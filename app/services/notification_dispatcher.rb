class NotificationDispatcher
  def self.dispatch_due(now: Time.current)
    new(now:).dispatch_due
  end

  def initialize(now: Time.current)
    @now = now
  end

  def dispatch_due
    Reminder.due.find_each do |reminder|
      dispatch_reminder(reminder)
    end
  end

  def dispatch_reminder(reminder)
    channels = reminder.user.notification_channels.enabled
    channels = [default_email_channel(reminder.user)] if channels.empty?

    channels.each do |channel|
      delivery = reminder.notification_deliveries.create!(notification_channel: channel)
      NotificationDeliveryJob.perform_later(delivery)
    end

    reminder.update!(last_notified_at: now)
  end

  private

  attr_reader :now

  def default_email_channel(user)
    user.notification_channels.find_or_create_by!(channel_type: :email, address: user.email) do |channel|
      channel.name = "Эл. почта аккаунта"
      channel.enabled = true
      channel.verified_at = now
    end
  end
end
