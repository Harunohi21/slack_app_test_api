# frozen_string_literal: true

require "base64"
require "digest"
require "aws-sdk-s3"
require "mime/types"
require "dropbox_api"

class GroupMessageController < ApplicationController
  client = DropboxApi::Client.new(ENV.fetch("DROPBOX_ACCESS_TOKEN"))

  def show
    @m_user = MUser.find_by(id: @current_user)
    @m_workspace = MWorkspace.find_by(id: @current_workspace)

    if params[:s_channel_id].nil?
      render json: { message: "Channel ID missing" }
      return
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: "User not found!" }
      return
    end

    file_records = []

    if params[:files].present?
      params[:files].each do |file|
        image_mime = file[:mime]
        image_data = decode(file[:data])
        file_name = file[:file_name]

        if MIME::Types[image_mime].empty?
          render json: { error: "Unsupported Content-Type" }, status: :unsupported_media_type
          return
        end
        file_extension = extension(image_mime)
        folder_name_for_group_message = "/group_message_files/#{SecureRandom.hex(10)}_#{file_name}"
        file_url = upload_to_dropbox(image_data, file_extension, folder_name_for_group_message)
        file_records << { file: file_url, mime_type: image_mime, extension: file_extension, file_name: file_name, m_user_id: @m_user.id }
      end
    end

    @t_group_message = TGroupMessage.new(
      groupmsg: params[:message],
      m_user_id: @m_user.id,
      m_channel_id: params[:s_channel_id],
      draft_message_status: params[:draft_message_status],
    )

    return unless @t_group_message.save

    file_records.each do |file_record|
      file_record[:t_group_message_id] = @t_group_message.id
      file_record[:groupmsgid] = @t_group_message.id
      TGroupMsgFile.create(file_record)
    end

    mention_name = params[:mention_name]

    unless mention_name.nil? || mention_name.empty?
      mention_name.each do |u_mention|
        u_mention[0] = ""
        @mention_user = MUser.find_by(name: u_mention)
        @t_group_mention_msg = TGroupMentionMsg.new(
          userid: @mention_user.id,
          groupmsgid: @t_group_message.id,
        )
        @t_group_mention_msg.save
      end
    end

    @t_user_channels = TUserChannel.where(channelid: params[:s_channel_id])

    @t_user_channels.each do |u_channel|
      next unless u_channel.userid != @m_user.id
      if (@t_group_message.draft_message_status != true)
        u_channel.message_count += 1
        temp_msgid = ""

        u_channel.unread_channel_message&.split(",")&.each do |u_message|
          temp_msgid += u_message
          temp_msgid += ","
        end
        temp_msgid += @t_group_message.id.to_s

        u_channel.unread_channel_message = temp_msgid
        TUserChannel.where(id: u_channel.id).update_all(message_count: u_channel.message_count,
                                                        unread_channel_message: u_channel.unread_channel_message)
      end
    end

    MUser.joins("INNER JOIN t_user_channels ON t_user_channels.userid = m_users.id
                   INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
         .where("m_channels.m_workspace_id = ? AND m_channels.id = ?",
                @m_workspace.id, params[:s_channel_id])
         .where.not("m_users.id = ?", @m_user.id)
         .update_all(remember_digest: "1")

    @m_channel_users = MUser.joins("INNER JOIN t_user_channels ON t_user_channels.userid = m_users.id
                                       INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
                            .where("m_users.member_status = true AND m_channels.m_workspace_id = ? AND m_channels.id = ?",
                                   @m_workspace.id, params[:s_channel_id])
                            .where.not("m_users.id = ?", @m_user.id)

    @m_channel_users.each do |user|
      MUser.where(id: user.id).update_all(remember_digest: "1")
    end

    @m_channel = MChannel.find_by(id: params[:s_channel_id])

    if MUsersProfileImage.find_by(m_user_id: @current_user.id).present?
      @sender_profile_image = MUsersProfileImage.find_by(m_user_id: @current_user.id).image_url
    end

    ActionCable.server.broadcast("group_message_channel", {
      message: @t_group_message,
      profile_image: @sender_profile_image,
      mention: mention_name,
      files: file_records,
      channel_id: @m_channel,
      sender_name: @m_user.name,
    })

    render json: { t_group_message: @t_group_message, mention: mention_name, t_group_msg_file: file_records }
  end

  def showthread
    @m_user = MUser.find_by(id: @current_user)
    @m_workspace = MWorkspace.find_by(id: @current_workspace)

    if params[:s_group_message_id].nil?
      @m_channel = MChannel.find_by(id: params[:s_channel_id]) unless params[:s_channel_id].nil?
    elsif params[:s_channel_id].nil?
      render json: { message: "Channel ID missing" }
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: "Channel not found!" }
    else
      @t_group_message = TGroupMessage.find_by(id: params[:s_group_message_id])

      if @t_group_message.nil?
        if params[:s_channel_id].nil?
          render json: { message: "Channel not found!" }
        else
          @m_channel = MChannel.find_by(id: params[:s_channel_id])
        end
      else
        file_records = []

        if params[:files].present?
          params[:files].each do |file|
            image_mime = file[:mime]
            image_data = decode(file[:data])
            file_name = file[:file_name]

            if MIME::Types[image_mime].empty?
              render json: { error: "Unsupported Content-Type" }, status: :unsupported_media_type
              return
            end
            folder_name_for_group_thread_message = "/group_thread_message_files/#{SecureRandom.hex(10)}_#{file_name}"
            file_extension = extension(image_mime)

            file_url = upload_to_dropbox(image_data, file_extension, folder_name_for_group_thread_message)

            file_records << { file: file_url, mime_type: image_mime, extension: file_extension, m_user_id: @m_user.id, file_name: file_name }
          end
        end

        @t_group_thread = TGroupThread.new(
          groupthreadmsg: params[:message],
          t_group_message_id: params[:s_group_message_id],
          m_user_id: @m_user.id,
          draft_message_status: params[:draft_message_status],
        )

        if @t_group_thread.save
          file_records.each do |file_record|
            file_record[:t_group_thread_id] = @t_group_thread.id
            file_record[:groupthreadmsgid] = @t_group_thread.id
            TGroupThreadMsgFile.create(file_record)
          end

          mention_name = params[:mention_name]

          unless mention_name.nil? || mention_name.empty?
            mention_name.each do |u_mention|
              u_mention[0] = ""
              @mention_user = MUser.find_by(name: u_mention)
              @t_group_mention_thread = TGroupMentionThread.new(
                userid: @mention_user.id,
                groupthreadid: @t_group_thread.id,
              )
              @t_group_mention_thread.save
            end
          end

          @t_user_channels = TUserChannel.where(channelid: params[:s_channel_id])

          @t_user_channels.each do |u_channel|
            next unless u_channel.userid != @m_user.id
            if (@t_group_thread.draft_message_status != true)
              u_channel.message_count += 1
              temp_msgid = ""
              unless u_channel.unread_thread_message.nil?
                arr_msgid = u_channel.unread_thread_message.split(",")
                unless arr_msgid.include? params[:s_group_message_id].to_s
                  u_channel.unread_thread_message.split(",").each do |u_message|
                    temp_msgid += u_message
                    temp_msgid += ","
                  end
                end
              end
              temp_msgid += @t_group_thread.id.to_s
              u_channel.unread_thread_message = temp_msgid
              TUserChannel.where(id: u_channel.id).update_all(message_count: u_channel.message_count,
                                                              unread_thread_message: u_channel.unread_thread_message)
            end
          end

          MUser.joins("INNER JOIN t_user_channels ON t_user_channels.userid = m_users.id")
               .where("t_user_channels.id = ?", params[:s_channel_id])
               .where.not("m_users.id = ?", @m_user.id)
               .update_all(remember_digest: "1")

          @m_channel_users = MUser.joins("INNER JOIN t_user_channels ON t_user_channels.userid = m_users.id
                                          INNER JOIN m_channels ON m_channels.id = t_user_channels.channelid")
                                  .where("m_users.member_status = true AND m_channels.m_workspace_id = ? AND m_channels.id = ?",
                                         @m_workspace.id, params[:s_channel_id])
                                  .where.not("m_users.id = ?", @m_user.id)

          @m_channel_users.each do |user|
            MUser.where(id: user.id).update_all(remember_digest: "1")
          end

          @m_channel = MChannel.find_by(id: params[:s_channel_id])

          if MUsersProfileImage.find_by(m_user_id: @m_user.id).present?
            @sender_profile_image = MUsersProfileImage.find_by(m_user_id: @m_user.id).image_url
          end

          ActionCable.server.broadcast("group_thread_message_channel", {
            message: @t_group_thread,
            profile_image: @sender_profile_image,
            mention: mention_name,
            files: file_records,
            channel_id: @m_channel,
            sender_name: @m_user.name,
          })

          render json: {
            t_group_thread: @t_group_thread,
            mention: mention_name,
            t_group_msg_file: file_records,
          }
        end
      end
    end
  end

  def deletemsg
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_channel_id].nil?
      render json: { error: "Channel ID missing" }
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { error: "Channel not found" }
    else
      gpthread = TGroupThread.select("id").where(t_group_message_id: params[:id])
      gpthread.each do |gpthread|
        TGroupThreadMsgFile.where(groupthreadmsgid: gpthread).each do |file|
          # delete_from_s3(file.file)
          delete_from_dropbox(file.file)
        end
        TGroupStarThread.where(groupthreadid: gpthread.id).destroy_all
        TGroupMentionThread.where(groupthreadid: gpthread.id).destroy_all
        TGroupReactThread.where(groupthreadid: gpthread.id).destroy_all
        TGroupThread.find_by(id: gpthread.id).destroy
      end

      TGroupMsgFile.where(groupmsgid: params[:id]).each do |file|
        # delete_from_s3(file.file)
        delete_from_dropbox(file.file)
      end

      TGroupStarMsg.where(groupmsgid: params[:id]).destroy_all
      TGroupMentionMsg.where(groupmsgid: params[:id]).destroy_all
      TGroupReactMsg.where(groupmsgid: params[:id]).destroy_all
      TGroupMsgFile.where(groupmsgid: params[:id]).destroy_all

      @delete_group_msg = TGroupMessage.find_by(id: params[:id]).delete
      @t_user_channels = TUserChannel.where(channelid: params[:s_channel_id])
      @t_user_channels.each do |u_channel|
        next unless u_channel.userid != @m_user.id

        u_channel.message_count -= (gpthread.size + 1)
        if u_channel.message_count.negative?
          TUserChannel.where(id: u_channel.id).update_all(message_count: 0)
        else
          TUserChannel.where(id: u_channel.id).update_all(message_count: u_channel.message_count)
        end
      end

      @m_channel = MChannel.find_by(id: params[:s_channel_id])
      ActionCable.server.broadcast("group_message_channel", {
        delete_msg: @delete_group_msg,
      })
      render json: { message: "Delete successful" }
    end
  end

  def deletethread
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_group_message_id].nil?
      unless params[:s_channel_id].nil?
        @m_channel = MChannel.find_by(id: params[:s_channel_id])
        render json: { message: "Channel ID missing" }
      end
    elsif params[:s_channel_id].nil?
      render json: { message: "Channel ID missing" }
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: "Channel not found" }
    else
      @t_group_thread = TGroupThread.find_by(id: params[:id])
      TGroupThreadMsgFile.where(groupthreadmsgid: @t_group_thread.id).each do |file|
        # delete_from_s3(file.file)
        delete_from_dropbox(file.file)
      end
      TGroupStarThread.where(groupthreadid: params[:id]).destroy_all
      TGroupReactThread.where(groupthreadid: params[:id]).destroy_all
      TGroupMentionThread.where(groupthreadid: params[:id]).destroy_all
      @delete_group_thread = TGroupThread.find_by(id: params[:id]).destroy

      TGroupThreadMsgFile.where(groupthreadmsgid: params[:id]).destroy_all
      @t_user_channels = TUserChannel.where(channelid: params[:s_channel_id])
      @t_user_channels.each do |u_channel|
        next unless u_channel.userid != @m_user.id
        u_channel.message_count -= 1
        TUserChannel.where(id: u_channel.id).update_all(message_count: u_channel.message_count)
      end

      @t_group_message = TGroupMessage.find_by(id: params[:s_group_message_id])
      ActionCable.server.broadcast("group_thread_message_channel", {
        delete_msg: @delete_group_thread,
      })
      render json: { message: "Group Thread Message has been deleted" }
    end
  end

  # group message edit
  def edit
    @t_group_message = TGroupMessage.find_by(id: params[:id])
    @mentionusers = TGroupMentionMsg.joins("JOIN t_group_messages ON t_group_messages.id = t_group_mention_msgs.groupmsgid ")
      .joins("JOIN m_users ON t_group_mention_msgs.userid = m_users.id ")
      .where("t_group_messages.id = ?", @t_group_message.id)
      .pluck("m_users.name")
    render json: { message: @t_group_message, mentionusers: @mentionusers }, status: :ok
  end

  # group message update
  def update
    t_group_message = TGroupMessage.where(id: params[:id]).first
    TGroupMentionMsg.where(groupmsgid: params[:id]).destroy_all
    message = params[:message]
    mention_name = params[:mention_name]
    # TGroupMentionMsg.where(groupmsgid: t_group_message.id).destroy_all
    unless mention_name.nil? || mention_name.empty?
      mention_name.each do |u_mention|
        u_mention[0] = ""
        @mention_user = MUser.find_by(name: u_mention)
        unless TGroupMentionMsg.exists?(userid: @mention_user.id, groupmsgid: t_group_message.id)
          @t_group_mention_msg = TGroupMentionMsg.new(
            userid: @mention_user.id,
            groupmsgid: t_group_message.id,
          )
          @t_group_mention_msg.save
        end
      end
    end
    TGroupMessage.where(id: t_group_message.id).update_all(groupmsg: message)

    if MUsersProfileImage.find_by(m_user_id: @current_user.id).present?
      @sender_profile_image = MUsersProfileImage.find_by(m_user_id: @current_user.id).image_url
    end

    @update_t_group_message = TGroupMessage.where(id: params[:id]).first

    ActionCable.server.broadcast("group_message_channel", {
      update_group_message: @update_t_group_message,
      profile_image: @sender_profile_image,
      mention: mention_name,
      sender_name: @current_user.name,
    })

    render json: { message: "group message updated successfully.", mention: mention_name }, status: :ok
  end

  # group message thread edit
  def edit_thread
    @t_group_thread = TGroupThread.find_by(id: params[:id])
    @mthreadusers = TGroupMentionThread.joins("JOIN t_group_threads ON t_group_threads.id = t_group_mention_threads.groupthreadid ")
      .joins("JOIN m_users ON t_group_mention_threads.userid = m_users.id ")
      .where("t_group_threads.id = ?", @t_group_thread.id)
      .pluck("m_users.name")
    render json: { message: @t_group_thread, mthreadusers: @mthreadusers }, status: :ok
  end

  # group message thread update
  def update_thread
    t_group_thread = TGroupThread.where(id: params[:id]).first
    TGroupMentionThread.where(groupthreadid: params[:id]).destroy_all

    message = params[:message]
    mention_name = params[:mention_name]

    unless mention_name.nil? || mention_name.empty?
      mention_name.each do |u_mention|
        u_mention[0] = ""
        @mention_user = MUser.find_by(name: u_mention)
        unless TGroupMentionThread.exists?(userid: @mention_user.id, groupthreadid: t_group_thread.id)
          @t_group_mention_thread = TGroupMentionThread.new(
            userid: @mention_user.id,
            groupthreadid: t_group_thread.id,
          )
          @t_group_mention_thread.save
        end
      end
    end
    TGroupThread.where(id: t_group_thread.id).update_all(groupthreadmsg: message)

    @update_t_group_thread = TGroupThread.where(id: params[:id]).first

    if MUsersProfileImage.find_by(m_user_id: @current_user.id).present?
      @sender_profile_image = MUsersProfileImage.find_by(m_user_id: @current_user.id).image_url
    end

    ActionCable.server.broadcast("group_thread_message_channel", {
      update_group_thread: @update_t_group_thread,
      profile_image: @sender_profile_image,
      mention: mention_name,
      sender_name: @current_user.name,
    })

    render json: { message: "group thread updated successfully.", mention: mention_name }, status: :ok
  end

  private

  def decode(data)
    Base64.decode64(data)
  end

  def extension(mime_type)
    mime = MIME::Types[mime_type].first
    raise "Unsupported Content-Type" unless mime

    mime.extensions.first ? ".#{mime.extensions.first}" : raise("Unknown extension for MIME type")
  end

  # def put_s3(data, extension, mime_type, folder)
  #   unique_time = Time.now.strftime("%Y%m%d%H%M%S")
  #   file_name = Digest::SHA1.hexdigest(data) + unique_time + extension
  #   s3 = Aws::S3::Resource.new
  #   bucket = s3.bucket("rails-blog-minio")
  #   obj = bucket.object("#{folder}/#{file_name}")

  #   obj.put(
  #     acl: "public-read",
  #     body: data,
  #     content_type: mime_type,
  #     content_disposition: "inline",
  #   )

  #   obj.public_url
  # end

  def upload_to_dropbox(image_data, extension, file_name)
    client = DropboxApi::Client.new(ENV["DROPBOX_ACCESS_TOKEN"])
    # filename = "/direct_message_files/#{SecureRandom.hex(10)}_#{file_name}"

    # Upload file to Dropbox
    client.upload(file_name, image_data)

    # Create a shared link for the uploaded file
    link = client.create_shared_link_with_settings(file_name)

    # Replace dl=0 with raw=1 or append raw=1 if dl=0 isn't present
    direct_link = if link.url.include?("?dl=0")
        link.url.gsub("?dl=0", "?raw=1")
      else
        "#{link.url}&raw=1"
      end

    return direct_link
  end

  # def delete_from_s3(url)
  #   s3 = Aws::S3::Resource.new
  #   bucket_name = "rails-blog-minio"
  #   file_path = url.split("#{bucket_name}/").last
  #   bucket = s3.bucket(bucket_name)
  #   obj = bucket.object(file_path)

  #   obj.delete
  # end

  def delete_from_dropbox(image_url)
    client = DropboxApi::Client.new(ENV["DROPBOX_ACCESS_TOKEN"])
    # Extract the path from the image URL to delete it from Dropbox
    path = extract_dropbox_path_from_url(image_url)
    client.delete(path)
  end
end
