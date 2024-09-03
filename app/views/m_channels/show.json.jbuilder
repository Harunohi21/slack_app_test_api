json.m_channel do 
    json.id @m_channel.id
    json.channel_name @m_channel.channel_name
    json.channel_status @m_channel.channel_status
    json.m_workspace @m_channel.m_workspace
end
if @retrieve_group_message
  json.retrieve_group_message @retrieve_group_message
end

if @retrievehome
  json.retrievehome @retrievehome
end