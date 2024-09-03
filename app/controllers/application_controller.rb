class ApplicationController < ActionController::API
  class_attribute :workspace_ides
  include JsonWebToken

  before_action :authenticate_request

  def retrievehome
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
    @m_user = MUser.find_by(id: @current_user)

    @m_users = MUser.select("m_users.id, m_users.name, m_users.email, m_users.password_digest, m_users.profile_image, m_users.remember_digest, m_users.active_status, m_users.admin, m_users.member_status, m_users.created_at, m_users.updated_at, m_users_profile_images.image_url")
      .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id
                          INNER JOIN t_user_workspaces ON t_user_workspaces.userid = m_users.id
                          INNER JOIN m_workspaces ON m_workspaces.id = t_user_workspaces.workspaceid
                          ")
      .where("(m_users.member_status = true and m_workspaces.id = ?)", @current_workspace)

    @m_channels = MChannel.select("m_channels.id, channel_name, channel_status, t_user_channels.message_count")
                          .joins("INNER JOIN t_user_channels ON t_user_channels.channelid = m_channels.id")
                          .where("(m_channels.m_workspace_id = ? and t_user_channels.userid = ?)", @current_workspace, @current_user)
                          .order(id: :asc)

    @m_p_channels = MChannel.select("m_channels.id, channel_name, channel_status")
                            .where("(m_channels.channel_status = true and m_channels.m_workspace_id = ?)", @current_workspace)
                            .order(id: :asc)

    @t_direct_draft = TDirectMessage.select(
      "m_users.name as name, directmsg, t_direct_messages.id as id, t_direct_messages.created_at as created_at, 
      m_users_profile_images.image_url, t_direct_messages.draft_message_status as draft_message_status, 
      t_direct_messages.send_user_id as send_user_id, m_users.active_status as sender_active_status, 
      receiver.active_status as active_status, receiver.name as receiver_name, receiver.id as receiver_id, 
      ARRAY_AGG(t_direct_message_files.file) as file_urls, ARRAY_AGG(t_direct_message_files.file_name) as file_names"
    )
      .joins(
        "INNER JOIN m_users ON m_users.id = t_direct_messages.send_user_id
      INNER JOIN m_users as receiver ON receiver.id = t_direct_messages.receive_user_id
      LEFT JOIN t_direct_message_files ON t_direct_message_files.t_direct_message_id = t_direct_messages.id
      LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id"
      )
      .where("t_direct_messages.draft_message_status != ? AND t_direct_messages.send_user_id = ?", false, @current_user.id)
      .group(
        "m_users.name, directmsg, t_direct_messages.id, t_direct_messages.created_at, 
      m_users_profile_images.image_url, t_direct_messages.draft_message_status, 
      t_direct_messages.send_user_id, m_users.active_status, 
      receiver.active_status, receiver.name, receiver.id"
      )
      .order("t_direct_messages.created_at ASC")

    @t_direct_thread_draft = TDirectThread.select(
      "m_users.name as name, t_direct_messages.id as direct_msg_id, directthreadmsg, m_users.active_status, 
      t_direct_threads.id as id, t_direct_threads.created_at as created_at, receiver.name as receiver_name, 
      receiver.id as receiver_id, m_users_profile_images.image_url, t_direct_threads.draft_message_status, 
      ARRAY_AGG(t_direct_thread_msg_files.file) as file_urls, ARRAY_AGG(t_direct_thread_msg_files.file_name) as file_names, 
      ARRAY_AGG(t_direct_message_files.file) as direct_files_urls, ARRAY_AGG(t_direct_message_files.file_name) as direct_file_names"
    )
      .joins(
        "INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id
      INNER JOIN m_users ON m_users.id = t_direct_threads.m_user_id
      LEFT JOIN t_direct_thread_msg_files ON t_direct_thread_msg_files.t_direct_thread_id = t_direct_threads.id
      LEFT JOIN t_direct_message_files ON t_direct_message_files.t_direct_message_id = t_direct_threads.t_direct_message_id
      LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id
      INNER JOIN m_users as receiver ON receiver.id = t_direct_messages.send_user_id"
      )
      .where("t_direct_threads.draft_message_status != ? AND t_direct_threads.m_user_id = ?", false, @current_user.id)
      .group(
        "m_users.name, t_direct_messages.id, directthreadmsg, m_users.active_status, t_direct_threads.id, 
      t_direct_threads.created_at, receiver.name, receiver.id, m_users_profile_images.image_url, 
      t_direct_threads.draft_message_status"
      )
      .order("t_direct_threads.id ASC")

    @t_group_draft = TGroupMessage.select(
      "name, groupmsg, t_group_messages.id as id, t_group_messages.created_at as created_at, 
      m_users_profile_images.image_url, m_channels.channel_name, t_group_messages.m_user_id as send_user_id, 
      t_group_messages.draft_message_status as draft_message_status, ARRAY_AGG(t_group_msg_files.file) as file_urls, 
      ARRAY_AGG(t_group_msg_files.file_name) as file_names"
    )
      .joins(
        "INNER JOIN m_users ON m_users.id = t_group_messages.m_user_id
      LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id
      INNER JOIN m_channels ON m_channels.id = t_group_messages.m_channel_id
      LEFT JOIN t_group_msg_files ON t_group_msg_files.t_group_message_id = t_group_messages.id"
      )
      .where("t_group_messages.draft_message_status != ? AND t_group_messages.m_user_id = ? ", false, @current_user.id)
      .group(
        "name, groupmsg, t_group_messages.id, t_group_messages.created_at, m_users_profile_images.image_url, m_channels.channel_name"
      )
      .order(created_at: :asc)

    @t_group_threads_draft = TGroupThread.select(
      "m_users.name as name, groupthreadmsg, t_group_messages.groupmsg, t_group_messages.id as group_msg_id, 
      t_group_messages.created_at as group_created_at, t_group_threads.id as id, t_group_threads.created_at as created_at, 
      m_channels.channel_name, m_channels.id as channel_id, t_group_threads.m_user_id as send_user_id, 
      m_users_profile_images.image_url, t_group_threads.draft_message_status as draft_message_status, 
      ARRAY_AGG(t_group_thread_msg_files.file) as file_url, ARRAY_AGG(t_group_thread_msg_files.file_name) as file_name, 
      ARRAY_AGG(t_group_msg_files.file) as group_file_url, ARRAY_AGG(t_group_msg_files.file_name) as group_file_name"
    )
      .joins(
        "INNER JOIN t_group_messages ON t_group_messages.id = t_group_threads.t_group_message_id
      INNER JOIN m_users ON m_users.id = t_group_threads.m_user_id
      INNER JOIN m_channels ON m_channels.id = t_group_messages.m_channel_id
      LEFT JOIN t_group_thread_msg_files ON t_group_thread_msg_files.t_group_thread_id = t_group_threads.id
      LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id
      LEFT JOIN t_group_msg_files ON t_group_msg_files.groupmsgid = t_group_threads.t_group_message_id"
      )
      .where("t_group_threads.draft_message_status != ? AND t_group_threads.m_user_id = ?", false, @current_user.id)
      .group(
        "m_users.name, groupthreadmsg, t_group_messages.groupmsg, t_group_messages.created_at, t_group_messages.id, 
      t_group_threads.id, t_group_threads.created_at, m_channels.channel_name, m_channels.id, 
      t_group_threads.m_user_id, m_users_profile_images.image_url, t_group_threads.draft_message_status"
      )
      .order("t_group_threads.id ASC")

    @direct_msgcounts = []
    @direct_draft_status_counts = []
    @m_users.each do |muser|
      direct_count = TDirectMessage.where(send_user_id: muser.id, receive_user_id: @current_user, draft_message_status: false, read_status: false)
      thread_count = TDirectThread.joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id")
                                  .where("t_direct_threads.read_status = false AND t_direct_threads.draft_message_status = false AND t_direct_threads.m_user_id = ? AND
                                          ((t_direct_messages.send_user_id = ? AND t_direct_messages.receive_user_id = ?) OR
                                           (t_direct_messages.send_user_id = ? AND t_direct_messages.receive_user_id = ?))",
                                         muser.id, muser.id, @current_user, @current_user, muser.id)
      @direct_msgcounts.push(direct_count.size + thread_count.size)
      direct_draft_count = TDirectMessage.where(receive_user_id: muser.id, send_user_id: @current_user.id, draft_message_status: true)
      @direct_draft_status_counts.push(direct_draft_count.size)
    end

    @group_draft_status_counts = []
    @m_channels.each do |mchannel|
      group_draft_count = TGroupMessage.where(m_channel_id: mchannel.id, draft_message_status: true, m_user_id: @current_user.id)
      @group_draft_status_counts.push(group_draft_count.size)
    end
    @all_unread_count = @m_channels.sum(&:message_count) + @direct_msgcounts.sum

    @m_channelsids = @m_channels.pluck(:id)

    @retrievehome = {
      m_users: @m_users,
      m_channels: @m_channels,
      direct_msgcounts: @direct_msgcounts,
      all_unread_count: @all_unread_count,
      m_channelsids: @m_channelsids,
      profile_image: @profile_image,
      direct_draft_status_counts: @direct_draft_status_counts,
      group_draft_status_counts: @group_draft_status_counts,
    }
  end

  def retrieve_direct_message
    @m_user = MUser.find_by(id: @current_user)

    TDirectMessage.where(send_user_id: params[:id], receive_user_id: @m_user.id, draft_message_status: false, read_status: false).update_all(read_status: true)
    TDirectThread.joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id")
                 .where("(t_direct_messages.receive_user_id = ? and t_direct_messages.send_user_id = ?) AND 
                        (t_direct_messages.receive_user_id = ? and t_direct_messages.send_user_id = ?)",
                        @m_user.id, params[:id], params[:id], @m_user.id)
                 .where.not(m_user_id: @m_user.id, draft_message_status: true, read_status: true).update_all(read_status: true)

    @temp_s_user = MUser.find_by(id: params[:id])
    profile_image_record = MUsersProfileImage.find_by(m_user_id: params[:id])
    image_url = profile_image_record ? profile_image_record.image_url : nil
    @s_user = @temp_s_user.as_json.merge(image_url: image_url)

    @t_direct_messages = TDirectMessage.select("name, directmsg, t_direct_messages.id as id, t_direct_messages.created_at as created_at, m_users_profile_images.image_url, t_direct_messages.draft_message_status as draft_message_status, t_direct_messages.send_user_id as send_user_id,
                                                ARRAY_AGG(t_direct_message_files.file) as file_urls, ARRAY_AGG(t_direct_message_files.file_name) as file_names,
                                                (select count(*) from t_direct_threads where t_direct_threads.t_direct_message_id = t_direct_messages.id AND t_direct_threads.draft_message_status = false) as count")
      .joins("INNER JOIN m_users ON m_users.id = t_direct_messages.send_user_id")
      .joins("LEFT JOIN t_direct_message_files ON t_direct_message_files.t_direct_message_id = t_direct_messages.id")
      .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
      .where("(t_direct_messages.receive_user_id = ? AND t_direct_messages.send_user_id = ?) OR 
                                                (t_direct_messages.receive_user_id = ? AND t_direct_messages.send_user_id = ?)",
             @m_user.id, params[:id], params[:id], @m_user.id)
      .group("name, directmsg, t_direct_messages.id, t_direct_messages.created_at, m_users_profile_images.image_url")
      .order(created_at: :desc)
    @t_direct_messages = @t_direct_messages.reverse

    @temp_direct_star_msgids = TDirectStarMsg.select("directmsgid").where("userid = ?", @m_user.id)
    @t_direct_star_msgids = @temp_direct_star_msgids.pluck(:directmsgid)

    @t_direct_message_dates = TDirectMessage.select("distinct DATE(created_at) as created_date")
                                            .where("(t_direct_messages.receive_user_id = ? AND t_direct_messages.send_user_id = ?) OR 
                                                   (t_direct_messages.receive_user_id = ? AND t_direct_messages.send_user_id = ?)",
                                                   @m_user.id, params[:id], params[:id], @m_user.id)
    @t_direct_message_datesize = @t_direct_messages.map { |d| d.created_at.strftime("%F").to_s }

    @temp_direct_react_msgids = TDirectReactMsg.select("directmsgid").distinct
    @t_direct_react_msgids = Array.new
    @temp_direct_react_msgids.each { |r| @t_direct_react_msgids.push(r.directmsgid) }

    @t_direct_msg_emojiscounts = TDirectReactMsg.select("t_direct_react_msgs.directmsgid, t_direct_react_msgs.emoji, COUNT(emoji) AS emoji_count")
      .joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_react_msgs.directmsgid")
      .group("t_direct_react_msgs.directmsgid, t_direct_react_msgs.emoji")
      .order("t_direct_react_msgs.directmsgid ASC")

    @react_usernames = MUser.select("t_direct_react_msgs.userid, m_users.name, t_direct_react_msgs.emoji, t_direct_react_msgs.directmsgid")
                            .joins("INNER JOIN t_direct_react_msgs ON m_users.id = t_direct_react_msgs.userid")
                            .joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_react_msgs.directmsgid")
                            .where("t_direct_messages.id = t_direct_react_msgs.directmsgid")
  end

  def retrieve_direct_thread(direct_message_id)
    @s_user = MUser.find_by(id: @current_user)
    # @t_direct_message = TDirectMessage.find_by(id: direct_message_id)
    @t_direct_message = TDirectMessage.select("t_direct_messages.id as id,
                                              directmsg, t_direct_messages.created_at as created_at,
                                              t_direct_messages.draft_message_status as draft_message_status,
                                              t_direct_messages.send_user_id as send_user_id,
                                              t_direct_messages.receive_user_id as receive_user_id,
                                              ARRAY_AGG(t_direct_message_files.file) as file_urls,
                                              ARRAY_AGG(t_direct_message_files.file_name) as file_names")
                                      .joins("LEFT JOIN t_direct_message_files ON t_direct_message_files.t_direct_message_id = t_direct_messages.id")
                                      .where("t_direct_messages.id = ?", direct_message_id)
                                      .group("t_direct_messages.id")
                                      .first

    m_userss = MUser.find_by(id: @t_direct_message.send_user_id)
    @send_username = m_userss.name

    @temp_send_user = MUser.find_by(id: @t_direct_message.send_user_id)
    suser_profile_image = MUsersProfileImage.find_by(m_user_id: @t_direct_message.send_user_id)
    suser_image_url = suser_profile_image ? suser_profile_image.image_url : nil
    @send_user = @temp_send_user.as_json.merge(image_url: suser_image_url)

    TDirectThread.where.not(m_user_id: @current_user, read_status: false).update_all(read_status: true)

    @t_direct_threads = TDirectThread.select("name, t_direct_threads.m_user_id, directthreadmsg, t_direct_threads.id as id, t_direct_threads.created_at as created_at, m_users_profile_images.image_url, t_direct_threads.draft_message_status, ARRAY_AGG(t_direct_thread_msg_files.file) as file_urls, ARRAY_AGG(t_direct_thread_msg_files.file_name) as file_names")
                                     .joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id
                                             INNER JOIN m_users ON m_users.id = t_direct_threads.m_user_id")
                                     .joins("LEFT JOIN t_direct_thread_msg_files ON t_direct_thread_msg_files.t_direct_thread_id = t_direct_threads.id")
                                     .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                     .where("t_direct_threads.t_direct_message_id = ?", direct_message_id)
                                     .group("name, t_direct_threads.m_user_id, directthreadmsg, t_direct_threads.id, t_direct_threads.created_at, m_users_profile_images.image_url")
                                     .order(id: :asc)

    @temp_direct_star_thread_msgids = TDirectStarThread.select("directthreadid").where("userid = ?", @current_user)
    @t_direct_star_thread_msgids = @temp_direct_star_thread_msgids.pluck(:directthreadid)

    @temp_direct_react_thread_msgids = TDirectReactThread.select("directthreadid").distinct
    @t_direct_react_thread_msgids = Array.new
    @temp_direct_react_thread_msgids.each { |r| @t_direct_react_thread_msgids.push(r.directthreadid) }

    @t_direct_thread_emojiscounts = TDirectReactThread.select("t_direct_react_threads.directthreadid, t_direct_react_threads.emoji, COUNT(emoji) AS emoji_count")
      .joins("INNER JOIN t_direct_threads ON t_direct_threads.id = t_direct_react_threads.directthreadid")
      .group("t_direct_react_threads.directthreadid, t_direct_react_threads.emoji")
      .order("t_direct_react_threads.directthreadid ASC")

    @react_usernames = MUser.select("t_direct_react_threads.userid, m_users.name, t_direct_react_threads.emoji, t_direct_react_threads.directthreadid")
                            .joins("INNER JOIN t_direct_react_threads ON m_users.id = t_direct_react_threads.userid")
                            .joins("INNER JOIN t_direct_threads ON t_direct_threads.id = t_direct_react_threads.directthreadid")
                            .where("t_direct_threads.id = t_direct_react_threads.directthreadid")

    @temp_direct_react_msgids = TDirectReactMsg.select("directmsgid")
      .where("directmsgid = ?", direct_message_id)
      .distinct

    @t_direct_react_msgids = Array.new
    @temp_direct_react_msgids.each { |r| @t_direct_react_msgids.push(r.directmsgid) }

    @t_direct_msg_emojiscounts = TDirectReactMsg.select("t_direct_react_msgs.directmsgid, t_direct_react_msgs.emoji, COUNT(emoji) AS emoji_count")
                                                .joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_react_msgs.directmsgid")
                                                .group("t_direct_react_msgs.directmsgid, t_direct_react_msgs.emoji")
                                                .where("t_direct_react_msgs.directmsgid = ?", direct_message_id)
                                                .order("t_direct_react_msgs.directmsgid ASC")

    @direct_react_usernames = MUser.select("t_direct_react_msgs.userid, m_users.name, t_direct_react_msgs.emoji, t_direct_react_msgs.directmsgid")
      .joins("INNER JOIN t_direct_react_msgs ON m_users.id = t_direct_react_msgs.userid")
      .joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_react_msgs.directmsgid")
      .where("t_direct_react_msgs.directmsgid = ?", direct_message_id)
  end

  def retrieve_group_message
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
    @m_user = MUser.find_by(id: @current_user)
    @s_channel = MChannel.find_by(id: params[:id])

    @m_channel_users = MUser.select("m_users.id, m_users.name, m_users.admin, m_users.email, m_users.active_status, m_users.member_status, t_user_channels.created_admin, t_user_channels.created_at, m_users_profile_images.image_url as profile_image")
                            .joins("INNER JOIN t_user_channels on t_user_channels.userid = m_users.id
                                    INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
                            .joins("LEFT JOIN m_users_profile_images on m_users_profile_images.m_user_id = m_users.id")
                            .where("m_users.member_status = true and m_channels.m_workspace_id = ? and m_channels.id = ?",
                                   @current_workspace, @s_channel)
                            .order("t_user_channels.created_at": :asc)

    TUserChannel.where(channelid: @s_channel, userid: @current_user).update_all(message_count: 0,
                                                                                unread_channel_message: nil, unread_thread_message: nil)

    @t_group_messages = TGroupMessage.select("name, groupmsg, t_group_messages.id as id, t_group_messages.created_at as created_at, m_users_profile_images.image_url,
                                              t_group_messages.m_user_id as send_user_id, t_group_messages.draft_message_status as draft_message_status, ARRAY_AGG(t_group_msg_files.file) as file_urls, ARRAY_AGG(t_group_msg_files.file_name) as file_names,
                                              (select count(*) from t_group_threads where t_group_threads.t_group_message_id = t_group_messages.id AND t_group_threads.draft_message_status = false) as count")
                                     .joins("INNER JOIN m_users ON m_users.id = t_group_messages.m_user_id")
                                     .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                     .joins("LEFT JOIN t_group_msg_files ON t_group_msg_files.t_group_message_id = t_group_messages.id")
                                     .where("m_channel_id = ?", @s_channel)
                                     .group("name, groupmsg, t_group_messages.id, t_group_messages.created_at, m_users_profile_images.image_url")
                                     .order(created_at: :desc)

    @t_group_messages = @t_group_messages.reverse

    @temp_group_star_msgids = TGroupStarMsg.select("groupmsgid").where("userid = ?", @current_user)
    @t_group_star_msgids = @temp_group_star_msgids.pluck(:groupmsgid)

    @u_count = TUserChannel.where(channelid: @s_channel).count
    @created_admin = TUserChannel.where("created_admin = true and channelid = ?", @s_channel)

    @t_group_message_dates = TGroupMessage.select("distinct DATE(created_at) as created_date").where("m_channel_id = ?", @s_channel)
    @t_group_message_datesize = @t_group_messages.map { |d| d.created_at.strftime("%F").to_s }

    @temp_group_react_msgids = TGroupReactMsg.select("groupmsgid").distinct

    @t_group_react_msgids = Array.new
    @temp_group_react_msgids.each { |r| @t_group_react_msgids.push(r.groupmsgid) }

    @emoji_counts = TGroupReactMsg.select("t_group_react_msgs.groupmsgid, t_group_react_msgs.emoji, COUNT(emoji) AS emoji_count")
                                  .joins("JOIN t_group_messages ON t_group_react_msgs.groupmsgid = t_group_messages.id")
                                  .where("t_group_react_msgs.groupmsgid = t_group_messages.id")
                                  .group("t_group_react_msgs.emoji, t_group_react_msgs.groupmsgid")
                                  .order("t_group_react_msgs.groupmsgid ASC")

    @react_usernames = MUser.select("t_group_react_msgs.userid, m_users.name, t_group_react_msgs.emoji, t_group_react_msgs.groupmsgid")
                            .joins("INNER JOIN t_group_react_msgs ON m_users.id = t_group_react_msgs.userid")
                            .joins("INNER JOIN t_group_messages ON t_group_messages.id = t_group_react_msgs.groupmsgid")
                            .where("t_group_messages.id = t_group_react_msgs.groupmsgid")

    @retrieve_group_message = {
      s_channel: @s_channel,
      t_group_messages: @t_group_messages,
      m_channel_users: @m_channel_users,
      t_group_star_msgids: @t_group_star_msgids,
      u_count: @u_count,
      created_admin: @created_admin,
      t_group_message_dates: @t_group_message_dates,
      t_group_message_datesize: @t_group_message_datesize,
      t_group_react_msgids: @t_group_react_msgids,
      emoji_counts: @emoji_counts,
      react_usernames: @react_usernames,
    }
  end

  def retrieve_group_thread
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
    @m_user = MUser.find_by(id: @current_user)
    @s_channel = MChannel.find_by(id: params[:s_channel_id])

    @m_channel_users = MUser.joins("INNER JOIN t_user_channels on t_user_channels.userid = m_users.id 
                                    INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
                            .where("m_users.member_status = true AND m_channels.m_workspace_id = ? AND m_channels.id = ?",
                                   @current_workspace, params[:s_channel_id])

    TUserChannel.where(channelid: params[:s_channel_id], userid: @current_user).update_all(message_count: 0, unread_channel_message: nil)

    # @t_group_message = TGroupMessage.find_by(id: params[:s_group_message_id])
    @t_group_message = TGroupMessage.select("groupmsg,
                                            t_group_messages.id as id,
                                            t_group_messages.created_at as created_at,
                                            t_group_messages.m_user_id,
                                            t_group_messages.draft_message_status as draft_message_status,
                                            ARRAY_AGG(t_group_msg_files.file) as file_urls,
                                            ARRAY_AGG(t_group_msg_files.file_name) as file_names")
                                    .joins("INNER JOIN m_users ON m_users.id = t_group_messages.m_user_id")
                                    .joins("LEFT JOIN t_group_msg_files ON t_group_msg_files.t_group_message_id = t_group_messages.id")
                                    .where("t_group_messages.id = ?", params[:s_group_message_id])
                                    .group("groupmsg, t_group_messages.id, t_group_messages.created_at ")
                                    .first

    @temp_send_user = MUser.find_by(id: @t_group_message.m_user_id)

    profile_image_record = MUsersProfileImage.find_by(m_user_id: @t_group_message.m_user_id)
    image_url = profile_image_record ? profile_image_record.image_url : nil
    @send_user = @temp_send_user.as_json.merge(image_url: image_url)

    @t_group_threads = TGroupThread.select("name, groupthreadmsg, t_group_threads.id as id, t_group_threads.created_at as created_at, 
                                            t_group_threads.m_user_id as send_user_id, m_users_profile_images.image_url, t_group_threads.draft_message_status as draft_message_status, ARRAY_AGG(t_group_thread_msg_files.file) as file_url, ARRAY_AGG(t_group_thread_msg_files.file_name) as file_name")
                                   .joins("INNER JOIN t_group_messages ON t_group_messages.id = t_group_threads.t_group_message_id
                                           INNER JOIN m_users ON m_users.id = t_group_threads.m_user_id")
                                   .joins("LEFT JOIN t_group_thread_msg_files ON t_group_thread_msg_files.t_group_thread_id = t_group_threads.id")
                                   .joins("LEFT JOIN m_users_profile_images ON m_users_profile_images.m_user_id = m_users.id")
                                   .where("t_group_threads.t_group_message_id = ?", params[:s_group_message_id])
                                   .group("name, groupthreadmsg, t_group_threads.id, t_group_threads.created_at, m_users_profile_images.image_url")
                                   .order(id: :asc)

    @temp_group_star_thread_msgids = TGroupStarThread.select("groupthreadid").where("userid = ?", @current_user)
    @t_group_star_thread_msgids = @temp_group_star_thread_msgids.pluck(:groupthreadid)

    @u_count = TUserChannel.where(channelid: params[:s_channel_id]).count

    @temp_group_react_thread_msgids = TGroupReactThread.select("groupthreadid").distinct

    @t_group_react_thread_msgids = Array.new
    @temp_group_react_thread_msgids.each { |r| @t_group_react_thread_msgids.push(r.groupthreadid) }

    @emoji_counts = TGroupReactThread.select("t_group_react_threads.groupthreadid, t_group_react_threads.emoji, COUNT(emoji) AS emoji_count")
      .joins("JOIN t_group_threads ON t_group_react_threads.groupthreadid = t_group_threads.id")
      .where("t_group_react_threads.groupthreadid = t_group_threads.id")
      .group("t_group_react_threads.emoji, t_group_react_threads.groupthreadid")
      .order("t_group_react_threads.groupthreadid ASC")

    @react_usernames = MUser.select("t_group_react_threads.userid, m_users.name, t_group_react_threads.emoji, t_group_react_threads.groupthreadid")
                            .joins("INNER JOIN t_group_react_threads ON m_users.id = t_group_react_threads.userid")
                            .joins("INNER JOIN t_group_threads ON t_group_threads.id = t_group_react_threads.groupthreadid")
                            .where("t_group_threads.id = t_group_react_threads.groupthreadid")

    @temp_group_react_msgids = TGroupReactMsg.select("groupmsgid")
      .where("groupmsgid = ?", params[:s_group_message_id])
      .distinct

    @t_group_react_msgids = Array.new
    @temp_group_react_msgids.each { |r| @t_group_react_msgids.push(r.groupmsgid) }

    @group_emoji_counts = TGroupReactMsg.select("t_group_react_msgs.groupmsgid, t_group_react_msgs.emoji, COUNT(t_group_react_msgs.emoji) AS emoji_count")
      .joins("JOIN t_group_messages ON t_group_react_msgs.groupmsgid = t_group_messages.id")
      .where("t_group_react_msgs.groupmsgid = ?", params[:s_group_message_id])
      .group("t_group_react_msgs.groupmsgid, t_group_react_msgs.emoji")
      .order("t_group_react_msgs.groupmsgid ASC")

    @group_react_usernames = MUser.select("t_group_react_msgs.userid, m_users.name, t_group_react_msgs.emoji, t_group_react_msgs.groupmsgid")
      .joins("INNER JOIN t_group_react_msgs ON m_users.id = t_group_react_msgs.userid")
      .joins("INNER JOIN t_group_messages ON t_group_messages.id = t_group_react_msgs.groupmsgid")
      .where("t_group_react_msgs.groupmsgid = ?", params[:s_group_message_id])

    @retrieveGroupThread = {
      s_channel: @s_channel,
      m_channel_users: @m_channel_users,
      t_group_message: @t_group_message,
      send_user: @send_user,
      t_group_threads: @t_group_threads,
      temp_group_star_thread_msgids: @temp_group_star_thread_msgids,
      t_group_star_thread_msgids: @t_group_star_thread_msgids,
      u_count: @u_count,
      t_group_react_thread_msgids: @t_group_react_thread_msgids,
      emoji_counts: @emoji_counts,
      react_usernames: @react_usernames,
      t_group_react_msgids: @t_group_react_msgids,
      group_emoji_counts: @group_emoji_counts,
      group_react_usernames: @group_react_usernames,
    }
  end

  private

  def authenticate_request
    header = request.headers["Authorization"]
    if header.present?
      token = header.split.last
      begin
        decoded = jwt_decode(token)
        @current_user = MUser.find(decoded[:user_id])
        profile_image_record = MUsersProfileImage.find_by(m_user_id: @current_user.id)
        image_url = profile_image_record ? profile_image_record.image_url : nil
        @m_current_user = @current_user.as_json.merge(profile_image_url: image_url)
        @current_workspace = MWorkspace.find(decoded[:workspace_id])
      rescue JWT::DecodeError
        render json: { error: "Invalid token" }, status: :unauthorized
      end
    else
      render json: { error: "Authorization header missing" }, status: :unauthorized
    end
  end
end
