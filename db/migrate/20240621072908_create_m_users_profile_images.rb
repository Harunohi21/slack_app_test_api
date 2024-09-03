class CreateMUsersProfileImages < ActiveRecord::Migration[7.1]
  def change
    create_table :m_users_profile_images do |t|

      t.string :image_url
      t.references :m_user, foreign_key: true

      t.timestamps
    end
  end
end
