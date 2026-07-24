namespace :reminders do
  desc "Dispatch due reminders and retry pending failed deliveries"
  task dispatch: :environment do
    NotificationDispatcher.dispatch_all
  end

  desc "Retry pending failed notification deliveries"
  task retry_failed: :environment do
    NotificationDispatcher.dispatch_retries
  end

  desc "Continuously dispatch due reminders and retries"
  task dispatch_loop: :environment do
    interval = ENV.fetch("REMINDER_DISPATCH_INTERVAL", "60").to_i.clamp(10, 3600)
    stop = false

    Signal.trap("TERM") { stop = true }
    Signal.trap("INT") { stop = true }

    until stop
      started_at = Time.current
      NotificationDispatcher.dispatch_all
      Rails.logger.info("reminders.dispatch_loop completed at #{started_at.iso8601}")
      sleep interval unless stop
    end
  end
end
