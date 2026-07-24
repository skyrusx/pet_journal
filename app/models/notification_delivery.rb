class NotificationDelivery < ApplicationRecord
  MAX_ATTEMPTS = 3
  RETRY_DELAYS = [5.minutes, 30.minutes].freeze

  belongs_to :reminder
  belongs_to :notification_channel

  enum :status, { pending: 0, sent: 1, failed: 2, skipped: 3 }, prefix: true

  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :due_for_retry, -> {
    status_pending
      .where("attempts_count > 0")
      .where("next_attempt_at IS NULL OR next_attempt_at <= ?", Time.current)
  }

  def mark_sent!
    update!(status: :sent, delivered_at: Time.current, next_attempt_at: nil, error_message: nil)
  end

  def register_attempt!
    increment!(:attempts_count)
  end

  def mark_failed!(message, now: Time.current)
    if retryable_after_failure?
      update!(status: :pending, next_attempt_at: next_retry_at(now), error_message: message.to_s)
    else
      update!(status: :failed, next_attempt_at: nil, error_message: message.to_s)
    end
  end

  def mark_skipped!(message)
    update!(status: :skipped, next_attempt_at: nil, error_message: message.to_s)
  end

  def reset_for_retry!
    update!(status: :pending, next_attempt_at: nil, error_message: nil)
  end

  def retryable_after_failure?
    attempts_count < MAX_ATTEMPTS
  end

  def next_retry_at(now = Time.current)
    now + RETRY_DELAYS.fetch(attempts_count - 1, RETRY_DELAYS.last)
  end

  def attempts_label
    "#{attempts_count}/#{MAX_ATTEMPTS}"
  end
end
