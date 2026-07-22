class CreatePetTagScans < ActiveRecord::Migration[7.2]
  def change
    create_table :pet_tag_scans do |t|
      t.references :pet_tag, null: false, foreign_key: true
      t.string :public_token, null: false
      t.text :user_agent
      t.string :referrer
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :location_note
      t.datetime :location_shared_at

      t.timestamps
    end

    add_index :pet_tag_scans, :public_token, unique: true
  end
end
