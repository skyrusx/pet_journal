class CreateReminders < ActiveRecord::Migration[7.2]
  def change
    create_table :reminders do |t|
      t.references :pet, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :reminder_type, null: false, default: 0
      t.datetime :remind_at, null: false
      t.datetime :next_run_at, null: false
      t.integer :repeat_rule, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.text :note
      t.datetime :last_completed_at

      t.timestamps
    end

    add_index :reminders, %i[status next_run_at]
  end
end
