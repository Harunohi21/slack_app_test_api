class TDirectReactMsgController < ApplicationController
  def create
    if params[:s_user_id].nil?
    else
      existing_reaction = TDirectReactMsg.find_by(
        directmsgid: params[:message_id],
        userid: params[:user_id],
        emoji: params[:emoji]
      )

      if existing_reaction.present?
        t_direct_react = existing_reaction.destroy
        @react_user_info = MUser.find_by(id: params[:user_id]).name

        ActionCable.server.broadcast("direct_message_channel", {
          remove_reaction: t_direct_react,
          reacted_user_info: @react_user_info
        })

        if (params[:status].present? && params[:status] == 0)
          ActionCable.server.broadcast("direct_thread_message_channel", {
            remove_direct_react: t_direct_react,
            direct_reacted_user_info: @react_user_info
          })
        end

        render json: { success: 'delete successful' }, status: :ok
      else
        @t_direct_react_msg = TDirectReactMsg.new(
          directmsgid: params[:message_id],
          userid: params[:user_id],
          emoji: params[:emoji]
        )

        @t_direct_react_msg.save
        @react_user_info = MUser.find_by(id: params[:user_id]).name
        
        ActionCable.server.broadcast("direct_message_channel", {
          react_message: @t_direct_react_msg,
          reacted_user_info: @react_user_info
        })

        if (params[:status].present? && params[:status] == 0)
          ActionCable.server.broadcast("direct_thread_message_channel", {
            direct_react_message: @t_direct_react_msg,
            direct_reacted_user_info: @react_user_info
          })
        end

        render json: { success: 'react successful' }, status: :ok
      end
    end
  end
end
