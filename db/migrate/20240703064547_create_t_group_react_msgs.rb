class CreateTGroupReactMsgs < ActiveRecord::Migration[7.1]
  def change
    create_table :t_group_react_msgs do |t|
      t.integer :groupmsgid
      t.integer :userid
      t.string :emoji

      t.timestamps
    end
  end
end
