class TDirectMessagesController < ApplicationController
  def show
    @direct_message_id = params[:direct_message_id]
    retrieve_direct_thread(@direct_message_id)
  end
end
