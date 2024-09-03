class DraftListsController < ApplicationController
  def show
    # Select direct draft messages from mysql database
    @t_direct_messages = TDirectMessage.select("t_direct_messages.id,t_direct_messages.directmsg, t_direct_messages.created_at, m_users.name")
                                        .joins('INNER JOIN m_users ON m_users.id = t_direct_messages.send_user_id')
                                        .where("t_direct_messages.draft_message_status != ? AND t_direct_messages.send_user_id = ?", false, @current_user.id)
                                        .order(created_at: :asc)
    
    @t_direct_threads = TDirectThread.select("t_direct_threads.t_direct_message_id, t_direct_threads.directthreadmsg, t_direct_threads.created_at, m_users.name")
                                      .joins("INNER JOIN t_direct_messages ON t_direct_messages.id = t_direct_threads.t_direct_message_id
                                      INNER JOIN m_users ON m_users.id = t_direct_threads.m_user_id
                                      INNER JOIN t_user_workspaces ON t_user_workspaces.userid = m_users.id")
                                      .where("t_direct_messages.id=t_direct_threads.t_direct_message_id and t_direct_threads.draft_message_status = true and t_direct_threads.m_user_id = ?", @current_user.id)
                                      .order(created_at: :asc)
                                      
    @t_group_messages = TGroupMessage.select('t_group_messages.id,t_group_messages.m_channel_id,t_group_messages.groupmsg,t_group_messages.created_at,m_users.name,m_channels.channel_name')
                                      .joins("INNER JOIN m_users ON m_users.id = t_group_messages.m_user_id
                                      INNER JOIN m_channels ON t_group_messages.m_channel_id=m_channels.id")
                                      .where("t_group_messages.draft_message_status = true and t_group_messages.m_user_id = ?", @current_user.id)
                                      .order(created_at: :asc)

    @t_group_threads = TGroupThread.select("t_group_threads.id,t_group_threads.m_user_id, t_group_threads.groupthreadmsg, t_group_threads.t_group_message_id, t_group_threads.created_at, m_users.name, m_channels.channel_name, (select m_channel_id from t_group_messages where t_group_threads.t_group_message_id = t_group_messages.id)")
                                    .joins("INNER JOIN t_group_messages ON t_group_messages.id = t_group_threads.t_group_message_id
                                    INNER JOIN m_users ON m_users.id = t_group_threads.m_user_id
                                    INNER JOIN m_channels ON t_group_messages.m_channel_id = m_channels.id")
                                    .where('t_group_messages.id = t_group_threads.t_group_message_id and t_group_threads.draft_message_status = true and t_group_threads.m_user_id = ?', @current_user.id).order('t_group_threads.created_at ASC')                                  
                                      
    
  end
end          