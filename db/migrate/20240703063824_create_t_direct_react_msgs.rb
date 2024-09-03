class CreateTDirectReactMsgs < ActiveRecord::Migration[7.1]
  def change
    create_table :t_direct_react_msgs do |t|
      t.integer :directmsgid
      t.integer :userid
      t.string :emoji

      t.timestamps
    end
  end
end
