class CreateTDirectMessageFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :t_direct_message_files do |t|
      t.string :file
      t.string :mime_type
      t.string :extension
      t.string :file_name
      t.integer :diirectmsgid
      t.references :t_direct_message, foreign_key: true
      t.references :m_user, foreign_key: true

      t.timestamps
    end
  end
end


