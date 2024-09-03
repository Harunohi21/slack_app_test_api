# frozen_string_literal: true

class StarListsController < ApplicationController
  def show
    @t_direct_messages = TDirectMessage.select('t_direct_messages.id, t_direct_messages.directmsg, t_direct_messages.created_at, m_users.name, m_users_profile_images.image_url as profile_image, ARRAY_AGG(distinct t_direct_message_files.file) as file_urls, ARRAY_AGG(distinct t_direct_message_files.file_name) as file_names')
                                       .joins("INNER JOIN t_direct_star_msgs ON t_direct_messages.id = t_direct_star_msgs.directmsgid
                                              INNER JOIN m_users ON m_users.id = t_direct_messages.send_user_id")
                                       .joins('LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id')
                                       .joins('LEFT JOIN t_direct_message_files on t_direct_message_files.t_direct_message_id = t_direct_messages.id')
                                       .where('t_direct_star_msgs.userid = ?', params[:user_id])
                                       .group('t_direct_messages.id, t_direct_messages.directmsg, t_direct_messages.created_at, m_users.name, m_users_profile_images.image_url')
                                       .order(id: :asc)

    @t_direct_threads = TDirectThread.select('t_direct_threads.id, t_direct_threads.directthreadmsg, t_direct_threads.created_at, m_users.name, m_users_profile_images.image_url as profile_image, ARRAY_AGG(distinct t_direct_thread_msg_files.file) as file_urls, ARRAY_AGG(distinct t_direct_thread_msg_files.file_name) as file_names')
                                     .joins("INNER JOIN t_direct_star_threads ON t_direct_threads.id = t_direct_star_threads.directthreadid
                                            INNER JOIN m_users ON m_users.id = t_direct_threads.m_user_id")
                                     .joins('LEFT JOIN m_users_profile_images on m_users_profile_images.m_user_id = m_users.id')
                                     .joins('LEFT JOIN t_direct_thread_msg_files on t_direct_thread_msg_files.direct_thread_id = t_direct_threads.id')
                                     .where('t_direct_star_threads.userid = ?', params[:user_id])
                                     .group('t_direct_threads.id, t_direct_threads.directthreadmsg, t_direct_threads.created_at, m_users.name, m_users_profile_images.image_url')
                                     .order(id: :asc)

    @t_group_messages = TGroupMessage.select('t_group_messages.id, t_group_messages.groupmsg, t_group_messages.created_at, m_users.name, m_channels.channel_name, m_users_profile_images.image_url as profile_image, ARRAY_AGG(distinct t_group_msg_files.file) as file_urls, ARRAY_AGG(distinct t_group_msg_files.file_name) as file_names')
                                     .joins("INNER JOIN t_group_star_msgs ON t_group_messages.id = t_group_star_msgs.groupmsgid
                                            INNER JOIN m_users ON t_group_messages.m_user_id = m_users.id
                                            INNER JOIN m_channels ON t_group_messages.m_channel_id = m_channels.id")
                                     .joins('LEFT JOIN m_users_profile_images on m_users_profile_images.m_user_id = m_users.id')
                                     .joins('LEFT JOIN t_group_msg_files on t_group_msg_files.t_group_message_id = t_group_messages.id')
                                     .where('t_group_star_msgs.userid = ?', params[:user_id])
                                     .group('t_group_messages.id, t_group_messages.groupmsg, t_group_messages.created_at, m_users.name, m_channels.channel_name, m_users_profile_images.image_url')
                                     .order(id: :asc)

    @t_group_threads = TGroupThread.select('t_group_threads.id, t_group_threads.groupthreadmsg, t_group_threads.created_at, m_users.name, m_channels.channel_name, m_users_profile_images.image_url as profile_image, ARRAY_AGG(distinct t_group_thread_msg_files.file) as file_urls, ARRAY_AGG(distinct t_group_thread_msg_files.file_name) as file_names')
                                   .joins("INNER JOIN t_group_star_threads ON t_group_threads.id = t_group_star_threads.groupthreadid
                                          INNER JOIN t_group_messages ON t_group_messages.id = t_group_threads.t_group_message_id
                                          INNER JOIN m_users ON t_group_threads.m_user_id = m_users.id
                                          INNER JOIN m_channels ON t_group_messages.m_channel_id = m_channels.id")
                                   .joins('LEFT JOIN m_users_profile_images on m_users_profile_images.m_user_id = m_users.id')
                                   .joins('LEFT JOIN t_group_thread_msg_files on t_group_thread_msg_files.t_group_thread_id = t_group_threads.id')
                                   .where('t_group_star_threads.userid = ?', params[:user_id])
                                   .group('t_group_threads.id, t_group_threads.groupthreadmsg, t_group_threads.created_at, m_users.name, m_channels.channel_name, m_users_profile_images.image_url')
                                   .order(id: :asc)
    # direct star
    @temp_direct_react_msgids = TDirectReactMsg.select('t_direct_react_msgs.directmsgid')
                                               .joins('INNER JOIN t_direct_star_msgs ON t_direct_star_msgs.directmsgid = t_direct_react_msgs.directmsgid').distinct
    @t_direct_react_msgids = []
    @temp_direct_react_msgids.each { |r| @t_direct_react_msgids.push(r.directmsgid) }

    @t_direct_msg_emojiscounts = TDirectReactMsg.select('t_direct_react_msgs.directmsgid, t_direct_react_msgs.emoji, COUNT(t_direct_react_msgs.emoji) AS emoji_count')
                                                .joins('INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_react_msgs.directmsgid')
                                                .joins('INNER JOIN t_direct_star_msgs ON t_direct_star_msgs.directmsgid = t_direct_react_msgs.directmsgid')
                                                .group('t_direct_react_msgs.directmsgid, t_direct_react_msgs.emoji')
                                                .order('t_direct_react_msgs.directmsgid ASC')

    @react_usernames = MUser.select('t_direct_react_msgs.userid, m_users.name, t_direct_react_msgs.emoji, t_direct_react_msgs.directmsgid')
                            .joins('INNER JOIN t_direct_react_msgs ON m_users.id = t_direct_react_msgs.userid')
                            .joins('INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_react_msgs.directmsgid')
                            .joins('INNER JOIN t_direct_star_msgs ON t_direct_star_msgs.directmsgid = t_direct_react_msgs.directmsgid')
                            .where('t_direct_messages.id = t_direct_react_msgs.directmsgid')

    # direct threads star
    @temp_direct_react_thread_msgids = TDirectReactThread.select('directthreadid')
                                                         .joins('INNER JOIN t_direct_star_threads ON t_direct_star_threads.directthreadid = t_direct_react_threads.directthreadid').distinct
    @t_direct_react_thread_msgids = []
    @temp_direct_react_thread_msgids.each { |r| @t_direct_react_thread_msgids.push(r.directthreadid) }

    @t_direct_thread_emojiscounts = TDirectReactThread.select('t_direct_react_threads.directthreadid, t_direct_react_threads.emoji, COUNT(emoji) AS emoji_count')
                                                      .joins('INNER JOIN t_direct_threads ON t_direct_threads.id = t_direct_react_threads.directthreadid')
                                                      .group('t_direct_react_threads.directthreadid, t_direct_react_threads.emoji')
                                                      .order('t_direct_react_threads.directthreadid ASC')

    @t_direct_thread_react_usernames = MUser.select('t_direct_react_threads.userid, m_users.name, t_direct_react_threads.emoji, t_direct_react_threads.directthreadid')
                                            .joins('INNER JOIN t_direct_react_threads ON m_users.id = t_direct_react_threads.userid')
                                            .joins('INNER JOIN t_direct_threads ON t_direct_threads.id = t_direct_react_threads.directthreadid')
                                            .where('t_direct_threads.id = t_direct_react_threads.directthreadid')

    # group star
    @temp_group_react_msgids = TGroupReactMsg.select('t_group_react_msgs.groupmsgid')
                                             .joins('INNER JOIN t_group_star_msgs ON t_group_react_msgs.groupmsgid = t_group_star_msgs.groupmsgid').distinct

    @t_group_react_msgids = []
    @temp_group_react_msgids.each { |r| @t_group_react_msgids.push(r.groupmsgid) }

    @group_emoji_counts = TGroupReactMsg.select('t_group_react_msgs.groupmsgid, t_group_react_msgs.emoji, COUNT(t_group_react_msgs.emoji) AS emoji_count')
                                        .joins('JOIN t_group_messages ON t_group_react_msgs.groupmsgid = t_group_messages.id')
                                        .joins('JOIN t_group_star_msgs ON t_group_star_msgs.groupmsgid = t_group_react_msgs.groupmsgid')
                                        .where('t_group_react_msgs.groupmsgid = t_group_messages.id')
                                        .group('t_group_react_msgs.emoji, t_group_react_msgs.groupmsgid')
                                        .order('t_group_react_msgs.groupmsgid ASC')

    @group_react_usernames = MUser.select('t_group_react_msgs.userid, m_users.name, t_group_react_msgs.emoji, t_group_react_msgs.groupmsgid')
                                  .joins('INNER JOIN t_group_react_msgs ON m_users.id = t_group_react_msgs.userid')
                                  .joins('JOIN t_group_star_msgs ON t_group_star_msgs.groupmsgid = t_group_react_msgs.groupmsgid')
                                  .joins('INNER JOIN t_group_messages ON t_group_messages.id = t_group_react_msgs.groupmsgid')
                                  .where('t_group_messages.id = t_group_react_msgs.groupmsgid')

    # group threads star
    @temp_group_react_thread_msgids = TGroupReactThread.select('t_group_react_threads.groupthreadid')
                                                       .joins('JOIN t_group_star_threads ON t_group_react_threads.groupthreadid = t_group_star_threads.groupthreadid').distinct

    @t_group_react_thread_msgids = []
    @temp_group_react_thread_msgids.each { |r| @t_group_react_thread_msgids.push(r.groupthreadid) }

    @t_group_thread_emoji_counts = TGroupReactThread.select('t_group_react_threads.groupthreadid, t_group_react_threads.emoji, COUNT(emoji) AS emoji_count')
                                                    .joins('JOIN t_group_threads ON t_group_react_threads.groupthreadid = t_group_threads.id')
                                                    .where('t_group_react_threads.groupthreadid = t_group_threads.id')
                                                    .group('t_group_react_threads.emoji, t_group_react_threads.groupthreadid')
                                                    .order('t_group_react_threads.groupthreadid ASC')

    @t_group_thread_react_usernames = MUser.select('t_group_react_threads.userid, m_users.name, t_group_react_threads.emoji, t_group_react_threads.groupthreadid')
                                           .joins('INNER JOIN t_group_react_threads ON m_users.id = t_group_react_threads.userid')
                                           .joins('INNER JOIN t_group_threads ON t_group_threads.id = t_group_react_threads.groupthreadid')
                                           .where('t_group_threads.id = t_group_react_threads.groupthreadid')
  end
end
