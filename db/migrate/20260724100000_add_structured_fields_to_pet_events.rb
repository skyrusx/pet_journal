class AddStructuredFieldsToPetEvents < ActiveRecord::Migration[7.2]
  def change
    add_column :pet_events, :weight_value, :decimal, precision: 6, scale: 2
    add_column :pet_events, :weight_unit, :string, null: false, default: "kg"
    add_column :pet_events, :vaccine_name, :string
    add_column :pet_events, :vaccine_batch, :string
    add_column :pet_events, :valid_until, :date
    add_column :pet_events, :clinic_name, :string
    add_column :pet_events, :veterinarian_name, :string
    add_column :pet_events, :medication_name, :string
    add_column :pet_events, :dosage, :string
    add_column :pet_events, :course_started_on, :date
    add_column :pet_events, :course_ended_on, :date
    add_column :pet_events, :next_action_at, :datetime
    add_column :pet_events, :diagnosis, :string
    add_column :pet_events, :recommendations, :text
    add_column :pet_events, :symptoms, :text
    add_column :pet_events, :severity, :integer
    add_column :pet_events, :symptom_started_on, :date
    add_column :pet_events, :symptom_ended_on, :date

    add_index :pet_events, :valid_until
    add_index :pet_events, :next_action_at
    add_index :pet_events, %i[pet_id event_type event_date]
  end
end
