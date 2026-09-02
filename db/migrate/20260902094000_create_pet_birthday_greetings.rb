class CreatePetBirthdayGreetings < ActiveRecord::Migration[7.2]
  def change
    create_table :pet_birthday_greetings do |t|
      t.references :user, null: false, foreign_key: true
      t.date :greeting_date, null: false
      t.datetime :shown_at
      t.datetime :email_sent_at

      t.timestamps
    end

    add_index :pet_birthday_greetings,
              %i[user_id greeting_date],
              unique: true,
              name: "index_pet_birthday_greetings_on_user_and_date"
  end
end
