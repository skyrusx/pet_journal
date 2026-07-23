class ReminderCompletion < ApplicationRecord
  belongs_to :reminder
  belongs_to :pet_event, optional: true

  validates :completed_at, presence: true
end
