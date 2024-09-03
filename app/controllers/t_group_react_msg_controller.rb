class TGroupReactMsgController < ApplicationController
  def create
    #check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_channel_id].nil?
      render json: { error: 'go to home'}, status: :ok
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { error: 'go to home'}, status: :ok
    else
      existing_reaction = TGroupReactMsg.find_by(groupmsgid: params[:message_id], userid: @m_user.id, emoji: params[:emoji])
      if existing_reaction.present?
        t_group_react = TGroupReactMsg.find_by(groupmsgid: params[:message_id], userid: @m_user.id, emoji: params[:emoji]).destroy
        @react_user_info = @m_user.name
        ActionCable.server.broadcast("group_message_channel", {
          remove_reaction: t_group_react,
          reacted_user_info: @react_user_info,
          m_channel_id: params[:s_channel_id],
        })
        if (params[:status].present? && params[:status] == 0)
          ActionCable.server.broadcast("group_thread_message_channel", {
            group_remove_reaction: t_group_react,
            group_reacted_user_info: @react_user_info,
            m_channel_id: params[:s_channel_id]
          })
        end
        render json: { message: 'delete successful'}, status: :ok
      else
        @t_group_react_msg = TGroupReactMsg.new
        @t_group_react_msg.groupmsgid = params[:message_id]
        @t_group_react_msg.userid = @m_user.id
        @t_group_react_msg.emoji = params[:emoji]
        @t_group_react_msg.save
        @react_user_info = @m_user.name
        ActionCable.server.broadcast("group_message_channel", {
          react_message: @t_group_react_msg,
          reacted_user_info: @react_user_info,
          m_channel_id: params[:s_channel_id]
        })

        if (params[:status].present? && params[:status] == 0)
          ActionCable.server.broadcast("group_thread_message_channel", {
            group_react_message: @t_group_react_msg,
            group_reacted_user_info: @react_user_info,
            m_channel_id: params[:s_channel_id]
          })
        end

        render json: { message: 'react successful'}, status: :ok
      end
    end
  end
end
