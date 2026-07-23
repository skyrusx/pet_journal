class NotificationDelivery < ApplicationRecord
  belongs_to :reminder
  belongs_to :notification_channel

  enum :status, { pending: 0, sent: 1, failed: 2, skipped: 3 }, prefix: true

  validates :status, presence: true

  def mark_sent!
    update!(status: :sent, delivered_at: Time.current, error_message: nil)
  end

  def mark_failed!(message)
    update!(status: :failed, error_message: message.to_s)
  end
end
