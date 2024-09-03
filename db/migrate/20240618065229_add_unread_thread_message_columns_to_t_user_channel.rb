class AddUnreadThreadMessageColumnsToTUserChannel < ActiveRecord::Migration[7.1]
  def up
    add_column :t_user_channels, :unread_thread_message, :string
  end
  
  def down
    remove_column :t_user_channels, :unread_thread_message, :string
  end
end
