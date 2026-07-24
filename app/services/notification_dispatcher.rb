class NotificationDispatcher
  def self.dispatch_all(now: Time.current)
    new(now:).dispatch_all
  end

  def self.dispatch_due(now: Time.current)
    new(now:).dispatch_due
  end

  def self.dispatch_retries(now: Time.current)
    new(now:).dispatch_retries
  end

  def initialize(now: Time.current)
    @now = now
  end

  def dispatch_all
    dispatch_due
    dispatch_retries
  end

  def dispatch_due
    Reminder.due.find_each do |reminder|
      dispatch_reminder(reminder)
    end
  end

  def dispatch_reminder(reminder)
    return if reminder.user.quiet_hours_now?(now)

    channels = channels_for(reminder)
    return if channels.empty?

    channels.each do |channel|
      delivery = reminder.notification_deliveries.create!(notification_channel: channel)
      if channel.ready_for_delivery?
        NotificationDeliveryJob.perform_later(delivery)
      else
        delivery.mark_skipped!(channel.configuration_issues.to_sentence)
      end
    end

    reminder.update!(last_notified_at: now)
  end

  def dispatch_retries
    NotificationDelivery.due_for_retry.includes(reminder: :pet).find_each do |delivery|
      next if delivery.reminder.user.quiet_hours_now?(now)

      NotificationDeliveryJob.perform_later(delivery)
    end
  end

  private

  attr_reader :now

  def channels_for(reminder)
    channels = reminder.notification_channels.enabled.to_a
    channels = reminder.user.notification_channels.enabled.to_a if reminder.notification_channels.empty?
    channels = [default_email_channel(reminder.user)] if channels.empty?
    channels
  end

  def default_email_channel(user)
    user.notification_channels.find_or_create_by!(channel_type: :email, address: user.email) do |channel|
      channel.name = "Эл. почта аккаунта"
      channel.enabled = true
      channel.verified_at = now
    end
  end
end
