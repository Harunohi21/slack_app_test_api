class TGroupMessagesController < ApplicationController
  def show
    if params[:s_channel_id].present?
      if MChannel.find_by(id: params[:s_channel_id]).nil?
        render json: { error: 'Cannot find channel' }, status: :not_found
      else
        params[:s_group_message_id] =  params[:id]
        retrieve_group_thread
        retrievehome
      end
    else
      render json: { error: 'Parameter s_channel_id is missing' }, status: :unprocessable_entity
    end
  end
end
