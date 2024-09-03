# frozen_string_literal: true

json.t_group_messages @t_group_messages do |t_group_message|
  json.id t_group_message.id
  json.groupmsg t_group_message.groupmsg
  json.created_at t_group_message.created_at
  json.name t_group_message.name
  json.file_urls t_group_message.file_urls
  json.file_names t_group_message.file_names
  json.profile_image t_group_message.profile_image
  json.channel_name t_group_message.channel_name
end
json.t_group_threads @t_group_threads do |t_group_thread|
  json.id t_group_thread.id
  json.groupthreadmsg t_group_thread.groupthreadmsg
  json.created_at t_group_thread.created_at
  json.name t_group_thread.name
  json.file_urls t_group_thread.file_urls
  json.file_names t_group_thread.file_names
  json.profile_image t_group_thread.profile_image
  json.channel_name t_group_thread.channel_name
end
json.t_group_star_msgids @t_group_star_msgids
json.t_group_star_thread_msgids @t_group_star_thread_msgids
json.t_group_react_msgids @t_group_react_msgids
json.group_emoji_counts @group_emoji_counts
json.group_react_usernames @group_react_usernames
json.t_group_react_thread_msgids @t_group_react_thread_msgids
json.group_thread_emoji_counts @group_thread_emoji_counts
json.group_thread_react_usernames @group_thread_react_usernames
