class CreatePetTags < ActiveRecord::Migration[7.2]
  def change
    create_table :pet_tags do |t|
      t.references :pet, null: false, foreign_key: true, index: { unique: true }
      t.string :public_token, null: false
      t.boolean :enabled, null: false, default: true
      t.text :public_message
      t.text :behavior_notes
      t.text :medical_notes
      t.string :contact_phone
      t.boolean :show_phone, null: false, default: false

      t.timestamps
    end

    add_index :pet_tags, :public_token, unique: true
  end
end
