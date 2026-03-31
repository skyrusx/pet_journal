class CreatePets < ActiveRecord::Migration[7.2]
  def change
    create_table :pets do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :species
      t.string :breed
      t.integer :sex
      t.date :birth_date
      t.decimal :weight, precision: 6, scale: 2
      t.string :color
      t.string :chip_number
      t.string :passport_number
      t.boolean :neutered
      t.text :notes

      t.timestamps
    end
  end
end
