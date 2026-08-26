class AddScheduleFieldsToPetEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :pet_events, :event_time, :time
    add_column :pet_events, :status, :integer, default: 1, null: false

    add_index :pet_events, [:pet_id, :status, :event_date]
  end
end
