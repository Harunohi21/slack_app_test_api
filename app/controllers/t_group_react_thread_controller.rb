class TGroupReactThreadController < ApplicationController
  def create
    #check unlogin user
    # checkuser
    @m_user = MUser.find_by(id: @current_user)
    if params[:s_group_message_id].nil?
      unless params[:s_channel_id].nil?
        @m_channel = MChannel.find_by(id: params[:s_channel_id])
        render json: { message: 'go to home'}, status: :ok
      end
    elsif params[:s_channel_id].nil?
      render json: { message: 'go to channel'}, status: :ok
    elsif MChannel.find_by(id: params[:s_channel_id]).nil?
      render json: { message: 'go to home'}, status: :ok
    else
      existing_reaction = TGroupReactThread.find_by(groupthreadid: params[:thread_id], userid: @m_user.id, emoji: params[:emoji])
      if existing_reaction.present?
        t_group_thread_react = TGroupReactThread.find_by(groupthreadid: params[:thread_id], userid: @m_user.id, emoji: params[:emoji]).destroy
        @react_user_info = @m_user.name
        ActionCable.server.broadcast("group_thread_message_channel", {
          remove_reaction: t_group_thread_react,
          reacted_user_info: @react_user_info,
          m_channel_id: params[:s_channel_id]
        })

        render json: { message: 'delete successful'}, status: :ok
      else
        @t_group_react_thread = TGroupReactThread.new
        @t_group_react_thread.groupthreadid = params[:thread_id]
        @t_group_react_thread.userid = @m_user.id
        @t_group_react_thread.emoji = params[:emoji]
        @t_group_react_thread.save
        @react_user_info = @m_user.name
        ActionCable.server.broadcast("group_thread_message_channel", {
          react_message: @t_group_react_thread,
          reacted_user_info: @react_user_info,
          m_channel_id: params[:s_channel_id]
        })
        render json: { message: 'react successful'}, status: :ok
      end
    end
  end
end
