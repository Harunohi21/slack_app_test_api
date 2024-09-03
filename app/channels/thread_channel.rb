class ThreadChannel < ApplicationCable::Channel
  def subscribed
     stream_from "direct_thread_message_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
