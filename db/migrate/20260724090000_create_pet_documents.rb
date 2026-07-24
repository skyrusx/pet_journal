class CreatePetDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :pet_documents do |t|
      t.references :pet, null: false, foreign_key: true
      t.references :pet_event, foreign_key: true
      t.references :reminder, foreign_key: true
      t.integer :document_type, null: false, default: 0
      t.string :title, null: false
      t.string :issuer
      t.string :number
      t.date :issued_on
      t.date :expires_on
      t.integer :expiry_reminder_days, null: false, default: 14
      t.text :notes

      t.timestamps
    end

    add_index :pet_documents, %i[pet_id document_type]
    add_index :pet_documents, :expires_on
  end
end
