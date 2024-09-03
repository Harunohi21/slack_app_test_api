class MChannelsController < ApplicationController
  before_action :set_m_channel, only: %i[show update destroy]

  def index
    @m_channels = MChannel.all
    render json: @m_channels
  end

  def show
    m_channel = MChannel.find_by(id: params[:id])
    if m_channel
      retrieve_group_message
      retrievehome
    else
      render json: { error: "MChannel not found" }, status: :not_found
    end
  end

  def create
    @m_channel = MChannel.new()
    @m_channel.channel_status = m_channel_params[:channel_status]
    @m_channel.m_workspace_id = m_channel_params[:m_workspace_id]
    @m_channel.channel_name = m_channel_params[:channel_name]
    
    if @m_channel.save
      @t_user_channel = TUserChannel.new
      @t_user_channel.message_count = 0
      @t_user_channel.unread_channel_message = nil
      @t_user_channel.created_admin = 1
      @t_user_channel.userid = m_channel_params[:user_id]
      @t_user_channel.channelid = @m_channel.id
      
      if @t_user_channel.save
        render json: @m_channel, status: :created, location: @m_channel
      end
    else
      render json: @m_channel.errors, status: :unprocessable_entity
    end
  end

  def update
    m_channel = MChannel.find_by(id: params[:id])
    
    if m_channel.nil?
      render json: @m_channel.errors, status: :unprocessable_entity
    else
      if @m_channel.channel_name.blank?
        render json: @m_channel.errors, status: :unprocessable_entity
      else
        m_channel.update(m_channel_params)
      end
    end
  end

  def destroy
    if MChannel.find_by(id: params[:id]).nil?
      render json: @m_channel.errors, status: :unprocessable_entity
    else
      group_messages = TGroupMessage.where(m_channel_id: params[:id])
      
      group_messages.each do |gmsg|
        gpthread = TGroupThread.select("id").where(t_group_message_id: gmsg.id)
        
        gpthread.each do |gpthread|
          TGroupStarThread.where(groupthreadid: gpthread.id).destroy_all
          TGroupReactThread.where(groupthreadid: gpthread.id).destroy_all
          TGroupThreadMsgFile.where(groupthreadmsgid: gpthread.id).destroy_all
          TGroupMentionThread.where(groupthreadid: gpthread.id).destroy_all
          TGroupThread.find_by(id: gpthread.id).destroy
        end
        
        TGroupStarMsg.where(groupmsgid: gmsg.id).destroy_all
        TGroupReactMsg.where(groupmsgid: gmsg.id).destroy_all
        TGroupMsgFile.where(groupmsgid: gmsg.id).destroy_all
        TGroupMentionMsg.where(groupmsgid: gmsg.id).destroy_all
        TGroupMessage.find_by(id: gmsg.id).delete
      end
      
      TUserChannel.where(channelid: params[:id]).destroy_all
      MChannel.find_by(id: params[:id]).delete
      @m_channels = MChannel.all
    end
  end

  def refresh_group
    if MChannel.find_by(id: params[:id]).nil?
      render json: @m_channel.errors, status: :unprocessable_entity
    else
      session[:r_group_size] ||= 10
      session[:r_group_size] += 10
    end
  end

  def edit
    if MChannel.find_by(id: params[:id]).nil?
      render json: @m_channel.errors, status: :unprocessable_entity
    else
      @m_channel = MChannel.find_by(id: params[:id])
      render json: {m_channel: @m_channel}, status: :ok
    end
  end

  private

  def set_m_channel
    @m_channel = MChannel.find(params[:id])
  end

  def m_channel_params
    params.require(:m_channel).permit(:channel_status, :channel_name, :m_workspace_id, :user_id)
  end
end
