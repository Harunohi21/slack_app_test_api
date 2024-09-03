class AddDraftMessageStatusColumnToTGroupMessages < ActiveRecord::Migration[7.1]
  def up
    add_column :t_group_messages, :draft_message_status, :boolean
  end
  
  def down
    remove_column :t_group_messages, :draft_message_status, :boolean
  end
end
