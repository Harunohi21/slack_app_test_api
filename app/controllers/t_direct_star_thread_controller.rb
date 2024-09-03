class TDirectStarThreadController < ApplicationController
  def create
    if params[:s_direct_message_id].nil?
      unless params[:s_user_id].nil?
        @user = MUser.find_by(id: params[:s_user_id])
        render json: { error: 'User not found' }, status: :unprocessable_entity
      end
    elsif params[:s_user_id].nil?
      render json: { error: 'User ID is missing' }, status: :not_found
    else
      @t_direct_star_thread = TDirectStarThread.new
      @t_direct_star_thread.userid = params[:user_id]
      @t_direct_star_thread.directthreadid = params[:id]
      @t_direct_star_thread.save

      @t_direct_message = TDirectMessage.find_by(id: params[:s_direct_message_id])
      ActionCable.server.broadcast("direct_thread_message_channel", {
        messaged_star: @t_direct_star_thread
      })
      render json: { success: 'Star successfully created' }, status: :ok
    end
  end

  def destroy
    if params[:s_direct_message_id].nil?
      unless params[:s_user_id].nil?
        @user = MUser.find_by(id: params[:s_user_id])
        render json: { error: 'User not found' }, sstatus: :unprocessable_entity
      end
    elsif params[:s_user_id].nil?
      render json: { error: 'User ID is missing' }, status: :not_found
    else
      @t_destroy_star_msg_thread = TDirectStarThread.find_by(directthreadid: params[:id], userid: params[:user_id]).destroy
      ActionCable.server.broadcast("direct_thread_message_channel", {
        unstared_message: @t_destroy_star_msg_thread
      })
      @t_direct_message = TDirectMessage.find_by(id: params[:s_direct_message_id])

      render json: { success: 'Star successfully deleted' }, status: :ok
    end
  end
end
