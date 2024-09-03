class CreateTGroupReactThreads < ActiveRecord::Migration[7.1]
  def change
    create_table :t_group_react_threads do |t|
      t.integer :groupthreadid
      t.integer :userid
      t.string :emoji

      t.timestamps
    end
  end
end
