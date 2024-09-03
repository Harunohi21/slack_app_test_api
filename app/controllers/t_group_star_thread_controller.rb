class TGroupStarThreadController < ApplicationController
  def create
    @m_user = MUser.find_by(id: @current_user)

    if params[:s_group_message_id].nil?
      unless params[:s_channel_id].nil?
        @m_channel = MChannel.find_by(id: params[:s_channel_id])
        render json: { message: 'Channel not found' }, status: :not_found
      end
    elsif params[:s_channel_id].nil?
      render json: { message: 'Channel ID is missing' }, status: :not_found
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: 'Channel not found' }, status: :unprocessable_entity
    else
      @t_group_star_thread = TGroupStarThread.new
      @t_group_star_thread.userid = @m_user.id
      @t_group_star_thread.groupthreadid = params[:id]
      @t_group_star_thread.save
      @t_group_message = TGroupMessage.find_by(id: params[:s_group_message_id])
      ActionCable.server.broadcast("group_thread_message_channel", {
        messaged_star: @t_group_star_thread
      })
      render json: { message: 'Create star successful' }, status: :ok
    end
  end

  def destroy
    @m_user = MUser.find_by(id: @current_user)

    if params[:s_group_message_id].nil?
      unless params[:s_channel_id].nil?
        @m_channel = MChannel.find_by(id: params[:s_channel_id])
        render json: { message: 'Channel not found' }, status: :unprocessable_entity
      end
    elsif params[:s_channel_id].nil?
      render json: { message: 'Channel ID is missing' }, status: :not_found
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: 'Channel not found' }, status: :unprocessable_entity
    else
      @t_group_unstar_thread = TGroupStarThread.find_by(groupthreadid: params[:id], userid: @m_user.id).destroy
      @t_group_message = TGroupMessage.find_by(id: params[:s_group_message_id])
      ActionCable.server.broadcast("group_thread_message_channel", {
        unstared_message: @t_group_unstar_thread
      })
      render json: { message: 'Delete star successful' }, status: :ok
    end
  end
end
