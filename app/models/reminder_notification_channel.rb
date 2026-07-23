class ReminderNotificationChannel < ApplicationRecord
  belongs_to :reminder
  belongs_to :notification_channel

  validate :channel_belongs_to_reminder_owner

  private

  def channel_belongs_to_reminder_owner
    return if reminder.blank? || notification_channel.blank?
    return if reminder.user == notification_channel.user

    errors.add(:notification_channel, :invalid)
  end
end
