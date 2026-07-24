class CreatePetProfileShares < ActiveRecord::Migration[7.2]
  def change
    create_table :pet_profile_shares do |t|
      t.references :pet, null: false, foreign_key: true
      t.string :public_token, null: false
      t.string :title, null: false
      t.boolean :enabled, null: false, default: true
      t.datetime :expires_at
      t.integer :detail_level, null: false, default: 0
      t.boolean :show_profile, null: false, default: true
      t.boolean :show_journal, null: false, default: true
      t.boolean :show_documents, null: false, default: true
      t.boolean :show_reminders, null: false, default: false
      t.boolean :show_pet_tag, null: false, default: false
      t.boolean :show_owner_contact, null: false, default: false
      t.boolean :allow_file_downloads, null: false, default: false
      t.datetime :token_rotated_at
      t.datetime :last_viewed_at

      t.timestamps
    end

    add_index :pet_profile_shares, :public_token, unique: true
    add_index :pet_profile_shares, %i[pet_id enabled]
    add_index :pet_profile_shares, :expires_at
  end
end
