class ChannelUserController < ApplicationController

  def show
    if params[:channel_id].nil?
      render json: { error: "Channel ID missing" }, status: :unprocessable_entity
    elsif MChannel.find_by(id: params[:channel_id]).nil?
      render json: { error: "Channel not found" }, status: :unprocessable_entity
    else
      @w_users = MUser.joins("INNER JOIN t_user_workspaces ON t_user_workspaces.userid = m_users.id")
                      .where("t_user_workspaces.workspaceid = ?", params[:workspace_id])

      @c_users = MUser.select("m_users.id, m_users.name, m_users.email, t_user_channels.created_admin")
                      .joins("INNER JOIN t_user_channels ON t_user_channels.userid = m_users.id")
                      .where("t_user_channels.channelid = ?", params[:channel_id])
                      .order(created_admin: :desc)

      @temp_c_users_id = MUser.select("id")
                              .joins("INNER JOIN t_user_channels ON t_user_channels.userid = m_users.id")
                              .where("t_user_channels.channelid = ?", params[:channel_id])
                              .order(created_admin: :desc)

      @c_users_id = @temp_c_users_id.pluck(:id)

      @s_channel = MChannel.find_by(id: params[:channel_id])
      retrievehome
    end
  end

  def create
    if params[:channel_id].nil?
      render json: { error: "Channel ID missing" }, status: :unprocessable_entity
    elsif MChannel.find_by(id: params[:channel_id]).nil?
      render json: { error: "Channel not found" }, status: :unprocessable_entity
    else
      @t_user_channel = TUserChannel.new(
        message_count: 0,
        unread_channel_message: 0,
        created_admin: 0,
        userid: params[:user_id],
        channelid: params[:channel_id]
      )

      if @t_user_channel.save
        render json: { message: "Successful" }, status: :ok
      else
        render json: @t_user_channel.errors, status: :unprocessable_entity
      end
    end
  end

  def join
    params[:id] = params[:channel_id]
    if params[:id].nil?
      render json: { error: "Channel ID missing" }, status: :unprocessable_entity
    elsif MChannel.find_by(id: params[:id]).nil?
      render json: { error: "Channel not found" }, status: :unprocessable_entity
    else
      @t_user_channel = TUserChannel.new(
        message_count: 0,
        unread_channel_message: 0,
        created_admin: 0,
        userid: params[:user_id],
        channelid: params[:id]
      )

      if @t_user_channel.save
        @m_channel = MChannel.find_by(id: params[:id])

        if @m_channel
          ActionCable.server.broadcast("channel_user_channel", {
            message: retrieve_group_message,
          })
        end

        render json: { message: "Successful Join" }, status: :ok
      else
        render json: @t_user_channel.errors, status: :unprocessable_entity
      end
    end
  end

  def destroy
    if params[:channel_id].nil?
      render json: { error: "Channel ID missing" }, status: :unprocessable_entity
    elsif MChannel.find_by(id: params[:channel_id]).nil?
      render json: { error: "Channel not found" }, status: :unprocessable_entity
    else
      t_user_channel = TUserChannel.find_by(userid: params[:id], channelid: params[:channel_id])
      if t_user_channel&.destroy
        ActionCable.server.broadcast("channel_user_channel", {
          message:  retrieve_group_message,
        })
        render json: { success: 'successful' }
      else
        render json: { error: 'Failed to delete user from channel' }, status: :unprocessable_entity
      end
    end
  end
end
