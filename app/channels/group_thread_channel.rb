class GroupThreadChannel < ApplicationCable::Channel
  def subscribed
    stream_from "group_thread_message_channel"
  end

  def unsubscribed
   
  end
end
