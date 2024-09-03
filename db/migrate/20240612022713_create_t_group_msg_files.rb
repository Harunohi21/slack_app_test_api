class CreateTGroupMsgFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :t_group_msg_files do |t|

      t.string :file
      t.string :mime_type
      t.string :extension
      t.string :file_name
      t.integer :groupmsgid
      t.references :t_group_message, foreign_key: true
      t.references :m_user, foreign_key: true

      t.timestamps
    end
   
  end
end

