require "base64"
require "digest"
require "aws-sdk-s3"
require "mime/types"
require "dropbox_api"

class MUsersController < ApplicationController
  skip_before_action :authenticate_request, only: [:login_user, :create, :confirm, :confirm_member_signup]

  def login_user
    m_user = MUser.find_by(name: login_params[:name])
    @user = MUser.find_by(id: m_user.id)
    MUser.where(id: @user).update_all(active_status: 1)

    m_workspace = MWorkspace.joins("INNER JOIN t_user_workspaces ON t_user_workspaces.workspaceid = m_workspaces.id
                                   INNER JOIN m_users ON m_users.id = t_user_workspaces.userid")
      .where("m_workspaces.workspace_name = ? and m_users.name = ?", login_params[:workspace_name], login_params[:name]).take(1)

    if m_user && m_user.authenticate(login_params[:password]) && m_workspace.size > 0
      t_user_workspace = TUserWorkspace.find_by(userid: m_user.id, workspaceid: m_workspace[0].id)
      if t_user_workspace
        if m_user.member_status == true
          token = jwt_encode(user_id: m_user.id, workspace_id: m_workspace[0].id)
          render json: { token: token }, status: :ok
        else
          render json: { error: "Account Deactivate. Please contact admin." }, status: :unauthorized
        end
      else
        render json: { error: "Invalid name/password combination" }, status: :not_found
      end
    else
      render json: { error: "Invalid name/password combination" }, status: :unprocessable_entity
    end
  end

  def logout
    @user = MUser.find_by(id: @current_user)
    MUser.where(id: @user).update_all(active_status: 0)
    render json: { message: "Sign Out Successfully" }
  end

  def confirm
    @m_workspace = MWorkspace.find_by(id: params[:workspaceid])
    @m_channel = MChannel.find_by(id: params[:channelid])
    @m_user = MUser.new
    @m_user.email = params[:email]
    @m_user.remember_digest = @m_workspace.workspace_name
    @m_user.profile_image = @m_channel.channel_name
  end

  def create
    @m_user = MUser.new(user_params)

    @m_workspace = MWorkspace.new
    @m_workspace.workspace_name = @m_user.remember_digest

    @m_channel = MChannel.new
    @m_channel.channel_name = @m_user.profile_image
    @m_channel.channel_status = 1

    @m_user.member_status = 1

    status = true

    @t_workspace = MWorkspace.find_by(id: params[:invite_workspaceid])

    if status && @m_user.save
      MUser.where(id: @m_user.id).update_all(remember_digest: nil, profile_image: nil)
    else
      status = false
    end

    if @t_workspace.nil?
      if status && @m_workspace.save
      else
        status = false
      end
    else
      @m_workspace = @t_workspace
    end

    @t_user_workspace = TUserWorkspace.new
    @t_user_workspace.userid = @m_user.id
    @t_user_workspace.workspaceid = @m_workspace.id

    if status && @t_user_workspace.save
    else
      status = false
    end

    @t_user_channel = TUserChannel.new
    @t_channel = MChannel.find_by(channel_name: @m_channel.channel_name, m_workspace_id: @m_workspace.id)

    if @t_channel.nil?
      @t_user_channel.created_admin = 1
      @m_channel.m_workspace_id = @m_workspace.id

      if status && @m_channel.save
      else
        status = false
      end
    else
      @t_user_channel.created_admin = 0
      @m_channel = @t_channel
    end

    @t_user_channel.message_count = 0
    @t_user_channel.unread_channel_message = 0
    @t_user_channel.userid = @m_user.id
    @t_user_channel.channelid = @m_channel.id

    if status && @t_user_channel.save
    else
      status = false
    end

    if status
      render json: { message: "Signup Complete." }, status: :ok
    else
      render json: { error: "Signup Failed." }, status: :unprocessable_entity
    end
  end

  def confirm_member_signup
    @m_user = MUser.new(user_params)
    @m_workspace = MWorkspace.new
    @m_workspace.workspace_name = @m_user.remember_digest
    @m_channel = MChannel.new
    @m_channel.channel_name = @m_user.profile_image
    @m_channel.channel_status = true
    @m_user.member_status = true
    status = true
    @t_workspace = MWorkspace.find_by(id: invite_workspace_id_param[:invite_workspaceid])
    if status && @m_user.save
      MUser.where(id: @m_user.id).update_all(remember_digest: nil, profile_image: nil)
    else
      status = false
    end
    if (@t_workspace.nil?)
      if status && @m_workspace.save
      else
        status = false
      end
    else
      @m_workspace = @t_workspace
    end
    @t_user_workspace = TUserWorkspace.new
    @t_user_workspace.userid = @m_user.id
    @t_user_workspace.workspaceid = @m_workspace.id
    if status && @t_user_workspace.save
    else
      status = false
    end
    @t_user_channel = TUserChannel.new
    @t_channel = MChannel.find_by(channel_name: @m_channel.channel_name, m_workspace_id: @m_workspace.id)
    if (@t_channel.nil?)
      @t_user_channel.created_admin = true
      @m_channel.m_workspace_id = @m_workspace.id
      if status && @m_channel.save
      else
        status = false
      end
    else
      @t_user_channel.created_admin = false
      @m_channel = @t_channel
    end
    @t_user_channel.message_count = 0
    @t_user_channel.unread_channel_message = 0
    @t_user_channel.userid = @m_user.id
    @t_user_channel.channelid = @m_channel.id
    if status && @t_user_channel.save
    else
      status = false
    end
    if (status)
      render json: { message: "Signup Complete." }, status: :ok
    else
      render json: { error: "Signup Failed." }, status: :unprocessable_entity
    end
  end

  def show
    retrieve_direct_message
    retrievehome
  end

  def show_home
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
    @m_user = MUser.find_by(id: @current_user)
    retrievehome if @m_user
  end

  def mainPage
    @m_workspace = MWorkspace.find_by(id: @current_workspace)
    @m_user = MUser.find_by(id: @current_user)
    retrievehome
  end

  def update
    @user = @current_user.id
    @m_user = MUser.new(user_params)
    old_password = params[:m_user][:old_password]
    password = params[:m_user][:password]
    password_confirmation = params[:m_user][:password_confirmation]
    user = MUser.find_by(id: @current_user.id)
    if user && user.authenticate(old_password)
      MUser.where(id: @user).update_all(password_digest: @m_user.password_digest)
      render json: { message: "Change Password Successful." }, status: :ok
    else
      render json: { error: "Your current password is wrong." }, status: :ok
    end
  end

  # user名変更
  def edit_username
    @username = params[:username]
    m_user = MUser.where(id: @current_user.id).first
    m_user.update!(name: @username)

    ActionCable.server.broadcast("profile_channel", {
      name: @username,
    })

    render json: { message: "Change Username Successful." }, status: :ok
  rescue ActiveRecord::RecordInvalid => e
    logger.error("exception: #{e.message}")
    render json: { error_message: e.record.errors.messages }, status: :unprocessable_entity
  end

  def profile_update
    image = params[:image]
    image_mime = image[:mime]
    encoded_image = image[:data]

    Rails.logger.info("parameters...")
    Rails.logger.info(image)
    Rails.logger.info(image_mime)

    if MIME::Types[image_mime].empty?
      return render json: { error: "Unsupported Content-Type" }, status: :unsupported_media_type
    end

    # Decode the base64 encoded image
    image_data = Base64.decode64(encoded_image.split(",").last)

    # Create a Tempfile to store the decoded image
    tempfile = Tempfile.new(["uploaded_image", ".jpg"])
    tempfile.binmode
    tempfile.write(image_data)
    tempfile.rewind

    # Check the image dimensions using MiniMagick
    image = MiniMagick::Image.read(tempfile)
    width, height = image.width, image.height

    if width > 500 || height > 500
      tempfile.close
      tempfile.unlink
      return render json: { error: "Image dimensions are too large" }, status: :unprocessable_entity
    end

    tempfile.close
    tempfile.unlink

    # Initialize Dropbox client (make sure to use a secure method for token)
    client = DropboxApi::Client.new(ENV.fetch["DROPBOX_ACCESS_TOKEN", nil]) # Use environment variable

    file_content = "Hello, Dropbox!"
    client.upload("/hello.txt", file_content)
    puts "File uploaded successfully!"

    # Upload the image to Dropbox
    dropbox_path = "/profile_image_#{Time.now.to_i}.jpg" # or any unique path
    client.upload(dropbox_path, image_data)

    # URL or path to the uploaded image in Dropbox
    image_url = client.get_temporary_link(dropbox_path).link

    @m_user = MUser.find_by(id: params[:user_id])

    if @m_user
      profile_image_record = MUsersProfileImage.find_or_initialize_by(m_user_id: @m_user.id)
      old_image_url = profile_image_record.image_url
      profile_image_record.image_url = image_url

      if profile_image_record.save
        # Optionally, you can delete the old image from Dropbox here
        # delete_from_dropbox(old_image_url) if old_image_url.present?

        render json: {
          message: "Profile Image Updated Successfully",
          user_id: @m_user.id,
          profile_image: image_url,
        }
      else
        render json: profile_image_record.errors, status: :unprocessable_entity
      end
    else
      render json: { error: "User not found" }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:m_user).permit(:name, :email, :password,
                                   :password_confirmation, :profile_image, :remember_digest, :admin)
  end

  def login_params
    params.require(:user).permit(:name, :password, :workspace_name)
  end

  def invite_workspace_id_param
    params.require(:workspace_id).permit(:invite_workspaceid)
  end

  def decode(data)
    Base64.decode64(data)
  end

  def extension(mime_type)
    mime = MIME::Types[mime_type].first
    raise "Unsupported Content-Type" unless mime
    mime.extensions.first ? ".#{mime.extensions.first}" : raise("Unknown extension for MIME type")
  end

  def put_s3(data, extension, mime_type)
    unique_time = Time.now.strftime("%Y%m%d%H%M%S")
    file_name = Digest::SHA1.hexdigest(data) + unique_time + extension
    s3 = Aws::S3::Resource.new
    bucket = s3.bucket("rails-blog-minio")
    obj = bucket.object("profile_images/#{file_name}")

    obj.put(
      acl: "public-read",
      body: data,
      content_type: mime_type,
      content_disposition: "inline",
    )

    obj.public_url
  end

  def delete_from_s3(url)
    s3 = Aws::S3::Resource.new
    bucket_name = "rails-blog-minio"
    file_path = url.split("#{bucket_name}/").last
    bucket = s3.bucket(bucket_name)
    obj = bucket.object(file_path)

    obj.delete
  end
end
