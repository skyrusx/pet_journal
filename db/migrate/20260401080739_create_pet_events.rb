class CreatePetEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :pet_events do |t|
      t.references :pet, null: false, foreign_key: true
      t.integer :event_type, null: false
      t.string :title
      t.date :event_date, null: false
      t.text :description

      t.timestamps
    end
  end
end
