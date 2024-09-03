class CreateTDirectReactThreads < ActiveRecord::Migration[7.1]
  def change
    create_table :t_direct_react_threads do |t|
      t.integer :directthreadid
      t.integer :userid
      t.string :emoji

      t.timestamps
    end
  end
end
