class CreatePetProfileShareViews < ActiveRecord::Migration[7.2]
  def change
    create_table :pet_profile_share_views do |t|
      t.references :pet_profile_share, null: false, foreign_key: true
      t.string :public_token, null: false
      t.text :user_agent
      t.string :referrer
      t.string :ip_address

      t.timestamps
    end

    add_index :pet_profile_share_views, %i[pet_profile_share_id created_at], name: "index_profile_share_views_on_share_and_created_at"
  end
end
