class TDirectStarMsgController < ApplicationController
  def create
    if params[:s_user_id].present?
      @t_direct_star_msg = TDirectStarMsg.new
      @t_direct_star_msg.userid = params[:user_id]
      @t_direct_star_msg.directmsgid = params[:id]
      @t_direct_star_msg.save

      @s_user = MUser.find_by(id: params[:s_user_id])

      ActionCable.server.broadcast("direct_message_channel", {
        messaged_star: @t_direct_star_msg
      })
      render json: { success: 'Star successful' }, status: :ok
    end
  end

  def destroy
   @t_destroy_star_msg = TDirectStarMsg.find_by(directmsgid: params[:id], userid: @current_user).destroy
    ActionCable.server.broadcast("direct_message_channel", {
        unstared_message: @t_destroy_star_msg
    })
    render json: { success: 'Unstar successful' }, status: :ok
  end
end
