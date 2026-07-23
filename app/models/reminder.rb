class Reminder < ApplicationRecord
  belongs_to :pet
  has_one :user, through: :pet
  has_many :notification_deliveries, dependent: :destroy
  has_many :reminder_notification_channels, dependent: :destroy
  has_many :notification_channels, through: :reminder_notification_channels

  enum :reminder_type, { other: 0, medication: 1, vaccination: 2, treatment: 3, visit: 4, weight: 5 }
  enum :repeat_rule, { once: 0, daily: 1, weekly: 2, monthly: 3 }
  enum :status, { active: 0, completed: 1, paused: 2 }, prefix: true

  validates :title, :remind_at, :next_run_at, presence: true

  before_validation :set_next_run_at, on: :create

  scope :due, -> {
    status_active
      .where("next_run_at <= ?", Time.current)
      .where("last_notified_at IS NULL OR last_notified_at < next_run_at")
  }
  scope :upcoming, -> { status_active.where("next_run_at >= ?", Time.current).order(:next_run_at) }
  scope :overdue, -> { status_active.where("next_run_at < ?", Time.current).order(:next_run_at) }

  def reminder_type_label
    I18n.t("reminders.types.#{reminder_type}")
  end

  def repeat_rule_label
    I18n.t("reminders.repeat_rules.#{repeat_rule}")
  end

  def due_today?
    next_run_at.to_date == Time.zone.today
  end

  def overdue?
    status_active? && next_run_at < Time.current
  end

  def complete!(completed_at: Time.current)
    if once?
      update!(status: :completed, last_completed_at: completed_at)
    else
      update!(last_completed_at: completed_at, next_run_at: next_future_occurrence_from(next_run_at), last_notified_at: nil)
    end
  end

  def next_occurrence_from(time)
    case repeat_rule
    when "daily" then time + 1.day
    when "weekly" then time + 1.week
    when "monthly" then time + 1.month
    else time
    end
  end

  def next_future_occurrence_from(time)
    occurrence = next_occurrence_from(time)
    occurrence = next_occurrence_from(occurrence) while occurrence <= Time.current
    occurrence
  end

  private

  def set_next_run_at
    self.next_run_at ||= remind_at
  end
end
