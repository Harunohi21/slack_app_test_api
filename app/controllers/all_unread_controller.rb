# frozen_string_literal: true

class AllUnreadController < ApplicationController
  def show
    # Select unread direct messages from postgres database
    @t_direct_messages = TDirectMessage.select(
      "t_direct_messages.id, t_direct_messages.directmsg, t_direct_messages.draft_message_status,
      t_direct_messages.created_at, m_users.name, m_users_profile_images.image_url as profile_image,
      ARRAY_AGG(t_direct_message_files.file) as file_urls, ARRAY_AGG(t_direct_message_files.file_name) as file_names"
    ).joins(
      'INNER JOIN m_users ON m_users.id = t_direct_messages.send_user_id'
    ).joins(
      'LEFT JOIN t_direct_message_files ON t_direct_message_files.t_direct_message_id = t_direct_messages.id'
    ).joins(
      'LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id'
    ).where(
      "t_direct_messages.send_user_id = m_users.id AND t_direct_messages.read_status = false AND
      t_direct_messages.receive_user_id = ? AND t_direct_messages.draft_message_status = ? ", params[:user_id], false
    ).group(
      't_direct_messages.id, t_direct_messages.directmsg, t_direct_messages.created_at, m_users.name, m_users_profile_images.image_url, t_direct_messages.draft_message_status'
    ).order(created_at: :asc)

    # Select reaction in unread direct messages from postgres database
    @temp_direct_react_msgids = TDirectReactMsg.select('directmsgid').distinct
    @t_direct_react_msgids = []
    @temp_direct_react_msgids.each { |r| @t_direct_react_msgids.push(r.directmsgid) }

    @t_direct_msg_emojiscounts = TDirectReactMsg
                                 .select('t_direct_react_msgs.directmsgid, t_direct_react_msgs.emoji, COUNT(t_direct_react_msgs.emoji) AS emoji_count')
                                 .joins('INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_react_msgs.directmsgid')
                                 .where('t_direct_messages.read_status = ? AND t_direct_messages.id = t_direct_react_msgs.directmsgid', false)
                                 .group('t_direct_react_msgs.directmsgid, t_direct_react_msgs.emoji')
                                 .order('t_direct_react_msgs.directmsgid ASC')

    @react_usernames = MUser.select('m_users.name, t_direct_react_msgs.emoji, t_direct_react_msgs.directmsgid')
                            .joins('INNER JOIN t_direct_react_msgs ON m_users.id = t_direct_react_msgs.userid')
                            .joins('INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_react_msgs.directmsgid')
                            .where('t_direct_messages.read_status = ? AND t_direct_messages.id = t_direct_react_msgs.directmsgid', false)

    # Select unread direct thread messages from postgres database
    @t_direct_threads = TDirectThread.select(
      "t_direct_threads.id as threadid, t_direct_threads.t_direct_message_id, t_direct_threads.directthreadmsg, t_direct_threads.draft_message_status,
      t_direct_threads.created_at, m_users.name, m_users_profile_images.image_url as profile_image,
      ARRAY_AGG(t_direct_thread_msg_files.file) as file_urls, ARRAY_AGG(t_direct_thread_msg_files.file_name) as file_names"
    ).joins(
      "INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id
      INNER JOIN m_users ON m_users.id = t_direct_threads.m_user_id
      INNER JOIN t_user_workspaces ON t_user_workspaces.userid = m_users.id"
    ).joins(
      'LEFT JOIN t_direct_thread_msg_files ON t_direct_thread_msg_files.t_direct_thread_id = t_direct_threads.id'
    ).joins(
      'LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id'
    ).where(
      "t_direct_messages.id = t_direct_threads.t_direct_message_id AND t_direct_threads.read_status = false AND t_direct_threads.m_user_id = m_users.id
      AND t_direct_threads.m_user_id <> ? AND t_user_workspaces.workspaceid = ? AND (t_direct_messages.receive_user_id = ? OR t_direct_messages.send_user_id = ?) AND t_direct_threads.draft_message_status = ? ",
      params[:user_id], params[:workspace_id], params[:user_id], params[:user_id], false
    ).group(
      't_direct_threads.id, t_direct_threads.t_direct_message_id, t_direct_threads.directthreadmsg, t_direct_threads.created_at, m_users.name, m_users_profile_images.image_url, t_direct_threads.draft_message_status'
    ).order(created_at: :asc)

    # Select reaction in unread direct threads messages from postgres database
    @temp_direct_react_thread_msgids = TDirectReactThread.select('directthreadid').distinct
    @t_direct_react_thread_msgids = []
    @temp_direct_react_thread_msgids.each { |r| @t_direct_react_thread_msgids.push(r.directthreadid) }

    @t_direct_thread_emojiscounts = TDirectReactThread.select('t_direct_react_threads.directthreadid, t_direct_react_threads.emoji, COUNT(emoji) AS emoji_count')
                                                      .joins('INNER JOIN t_direct_threads ON t_direct_threads.id = t_direct_react_threads.directthreadid')
                                                      .group('t_direct_react_threads.directthreadid, t_direct_react_threads.emoji')
                                                      .where('t_direct_threads.read_status = ? AND t_direct_threads.id = t_direct_react_threads.directthreadid', false)
                                                      .order('t_direct_react_threads.directthreadid ASC')

    @threads_react_usernames = MUser.select('m_users.name, t_direct_react_threads.emoji, t_direct_react_threads.directthreadid')
                                    .joins('INNER JOIN t_direct_react_threads ON m_users.id = t_direct_react_threads.userid')
                                    .joins('INNER JOIN t_direct_threads ON t_direct_threads.id = t_direct_react_threads.directthreadid')
                                    .where('t_direct_threads.id = t_direct_react_threads.directthreadid')

    # Select unread group messages from postgres database
    @temp_user_channelids = TUserChannel.select('unread_channel_message')
                                        .where('message_count > 0 AND userid = ?', params[:user_id])
    @temp_user_channelthreadids = TUserChannel.select('unread_thread_message')
                                              .where('message_count > 0 AND userid = ?', params[:user_id])

    @tmp_user_channelids = []
    @t_user_channelids = []
    @temp_user_channelids.each do |u_channel|
      @tmp_user_channelids << u_channel.unread_channel_message.split(',') unless u_channel.unread_channel_message.nil?
    end
    @t_user_channelids = @tmp_user_channelids.flatten

    @tmp_user_channelthreadids = []
    @t_user_channelthreadids = []
    @temp_user_channelthreadids.each do |u_channel_thread|
      unless u_channel_thread.unread_thread_message.nil?
        @tmp_user_channelthreadids << u_channel_thread.unread_thread_message.split(',')
      end
    end
    @t_user_channelthreadids = @tmp_user_channelthreadids.flatten

    @t_group_messages = TGroupMessage.select(
      "t_group_messages.id, t_group_messages.m_channel_id, t_group_messages.groupmsg, t_group_messages.draft_message_status, t_group_messages.created_at, m_users.name, m_channels.channel_name, m_channels.channel_status,
      (SELECT COUNT(*) FROM t_group_threads WHERE t_group_threads.t_group_message_id = t_group_messages.id) AS count, m_channels.channel_name, m_users_profile_images.image_url AS profile_image,
      ARRAY_AGG(t_group_msg_files.file) AS file_urls, ARRAY_AGG(t_group_msg_files.file_name) AS file_names"
    ).joins(
      "INNER JOIN m_users ON m_users.id = t_group_messages.m_user_id
      INNER JOIN m_channels ON t_group_messages.m_channel_id = m_channels.id"
    ).joins(
      'LEFT JOIN t_group_msg_files ON t_group_msg_files.t_group_message_id = t_group_messages.id'
    ).joins(
      'LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id'
    ).where(
      't_group_messages.draft_message_status = ? ', false
    ).group(
      't_group_messages.id, t_group_messages.m_channel_id, t_group_messages.groupmsg, t_group_messages.created_at, m_users.name, m_channels.channel_name, m_channels.channel_status, m_users_profile_images.image_url, t_group_messages.draft_message_status'
    ).order(created_at: :asc)
    

    # Select reaction in unread group messages from postgres database
    @temp_group_react_msgids = TGroupReactMsg.select('groupmsgid').distinct

    @t_group_react_msgids = []
    @temp_group_react_msgids.each { |r| @t_group_react_msgids.push(r.groupmsgid) }

    @group_emoji_counts = TGroupReactMsg.select('t_group_react_msgs.groupmsgid, t_group_react_msgs.emoji, COUNT(emoji) AS emoji_count')
                                        .joins('JOIN t_group_messages ON t_group_react_msgs.groupmsgid = t_group_messages.id')
                                        .where('t_group_react_msgs.groupmsgid = t_group_messages.id')
                                        .group('t_group_react_msgs.emoji, t_group_react_msgs.groupmsgid')
                                        .order('t_group_react_msgs.groupmsgid ASC')

    @group_react_usernames = MUser.select('m_users.name, t_group_react_msgs.emoji, t_group_react_msgs.groupmsgid')
                                  .joins('INNER JOIN t_group_react_msgs ON m_users.id = t_group_react_msgs.userid')
                                  .joins('INNER JOIN t_group_messages ON t_group_messages.id = t_group_react_msgs.groupmsgid')
                                  .where('t_group_messages.id = t_group_react_msgs.groupmsgid')

    @t_group_threads = TGroupThread.select(
      "t_group_threads.id, t_group_threads.m_user_id, t_group_threads.groupthreadmsg, t_group_threads.t_group_message_id, t_group_threads.draft_message_status, t_group_threads.created_at, m_users.name, m_channels.channel_name,
      m_users_profile_images.image_url AS profile_image, ARRAY_AGG(t_group_thread_msg_files.file) AS file_urls, ARRAY_AGG(t_group_thread_msg_files.file_name) AS file_names,
      (SELECT m_channel_id FROM t_group_messages WHERE t_group_threads.t_group_message_id = t_group_messages.id)"
    ).joins(
      "INNER JOIN t_group_messages ON t_group_messages.id = t_group_threads.t_group_message_id
      INNER JOIN m_users ON m_users.id = t_group_threads.m_user_id
      INNER JOIN m_channels ON t_group_messages.m_channel_id = m_channels.id"
    ).joins(
      'LEFT JOIN t_group_thread_msg_files ON t_group_thread_msg_files.t_group_thread_id = t_group_threads.id'
    ).joins(
      'LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id'
    ).where(
      't_group_messages.id = t_group_threads.t_group_message_id AND t_group_threads.draft_message_status = ? ', false
    ).group(
      't_group_threads.id, t_group_threads.m_user_id, t_group_threads.groupthreadmsg, t_group_threads.t_group_message_id, t_group_threads.created_at, m_users.name, m_channels.channel_name, m_users_profile_images.image_url, t_group_threads.draft_message_status'
    ).order('t_group_threads.created_at ASC')

    # Select reaction in unread group thread messages from postgres database
    @temp_group_react_thread_msgids = TGroupReactThread.select('groupthreadid').distinct

    @t_group_react_thread_msgids = []
    @temp_group_react_thread_msgids.each { |r| @t_group_react_thread_msgids.push(r.groupthreadid) }

    @group_threads_emoji_counts = TGroupReactThread.select('t_group_react_threads.groupthreadid, t_group_react_threads.emoji, COUNT(emoji) AS emoji_count')
                                                   .joins('JOIN t_group_threads ON t_group_react_threads.groupthreadid = t_group_threads.id')
                                                   .where('t_group_react_threads.groupthreadid = t_group_threads.id')
                                                   .group('t_group_react_threads.emoji, t_group_react_threads.groupthreadid')
                                                   .order('t_group_react_threads.groupthreadid ASC')

    @group_threads_react_usernames = MUser.select('m_users.name, t_group_react_threads.emoji, t_group_react_threads.groupthreadid')
                                          .joins('INNER JOIN t_group_react_threads ON m_users.id = t_group_react_threads.userid')
                                          .joins('INNER JOIN t_group_threads ON t_group_threads.id = t_group_react_threads.groupthreadid')
                                          .where('t_group_threads.id = t_group_react_threads.groupthreadid')

    retrievehome
  end
end
