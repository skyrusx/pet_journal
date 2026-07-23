class CompleteReminders < ActiveRecord::Migration[7.2]
  def change
    add_column :reminders, :repeat_interval, :integer, null: false, default: 1
    add_column :reminders, :repeat_unit, :integer, null: false, default: 1
    add_index :reminders, %i[status reminder_type next_run_at]

    create_table :reminder_completions do |t|
      t.references :reminder, null: false, foreign_key: true
      t.references :pet_event, foreign_key: true
      t.datetime :completed_at, null: false
      t.boolean :event_created, null: false, default: false
      t.text :note

      t.timestamps
    end

    add_index :reminder_completions, %i[reminder_id completed_at]
  end
end
