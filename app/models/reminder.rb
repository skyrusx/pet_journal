class Reminder < ApplicationRecord
  belongs_to :pet
  has_one :user, through: :pet
  has_many :notification_deliveries, dependent: :destroy
  has_many :reminder_notification_channels, dependent: :destroy
  has_many :notification_channels, through: :reminder_notification_channels
  has_many :reminder_completions, dependent: :destroy

  enum :reminder_type, { other: 0, medication: 1, vaccination: 2, treatment: 3, visit: 4, weight: 5 }
  enum :repeat_rule, { once: 0, daily: 1, weekly: 2, monthly: 3, yearly: 4, custom: 5 }
  enum :repeat_unit, { days: 0, weeks: 1, months: 2, years: 3 }, prefix: :repeat
  enum :status, { active: 0, completed: 1, paused: 2 }, prefix: true

  validates :title, :remind_at, :next_run_at, presence: true
  validates :repeat_interval, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 99 }

  before_validation :set_next_run_at, on: :create
  before_validation :normalize_repeat_settings

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
    return I18n.t("reminders.repeat_rules.custom", count: repeat_interval, unit: repeat_unit_label) if custom?

    I18n.t("reminders.repeat_rules.#{repeat_rule}")
  end

  def repeat_unit_label
    forms = {
      "days" => %w[день дня дней],
      "weeks" => %w[неделю недели недель],
      "months" => %w[месяц месяца месяцев],
      "years" => %w[год года лет]
    }.fetch(repeat_unit)
    count = repeat_interval % 100

    return forms[2] if count.between?(11, 14)

    case repeat_interval % 10
    when 1 then forms[0]
    when 2..4 then forms[1]
    else forms[2]
    end
  end

  def due_today?
    next_run_at.to_date == Time.zone.today
  end

  def overdue?
    status_active? && next_run_at < Time.current
  end

  def complete!(completed_at: Time.current, pet_event: nil, note: nil)
    reminder_completions.create!(
      completed_at:,
      pet_event:,
      event_created: pet_event.present?,
      note:
    )

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
    when "yearly" then time + 1.year
    when "custom" then time + repeat_interval.public_send(repeat_unit)
    else time
    end
  end

  def snooze_until!(time)
    update!(next_run_at: time, last_notified_at: nil, status: :active)
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

  def normalize_repeat_settings
    self.repeat_interval = 1 unless custom?
    self.repeat_unit = default_repeat_unit unless custom?
  end

  def default_repeat_unit
    case repeat_rule
    when "daily" then :days
    when "weekly" then :weeks
    when "monthly" then :months
    when "yearly" then :years
    else :days
    end
  end
end
