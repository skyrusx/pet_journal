namespace :reminders do
  desc "Dispatch due reminders and retry pending failed deliveries"
  task dispatch: :environment do
    ActiveJob::Base.queue_adapter = :inline

    due_count = Reminder.due.count
    retry_count = NotificationDelivery.due_for_retry.count
    deliveries_before = NotificationDelivery.count

    NotificationDispatcher.dispatch_all
    BirthdayGreetingDispatchJob.perform_now

    puts "Due reminders: #{due_count}"
    puts "Retry deliveries: #{retry_count}"
    puts "Created deliveries: #{NotificationDelivery.count - deliveries_before}"
  end

  desc "Retry pending failed notification deliveries"
  task retry_failed: :environment do
    ActiveJob::Base.queue_adapter = :inline

    retry_count = NotificationDelivery.due_for_retry.count
    NotificationDispatcher.dispatch_retries

    puts "Retry deliveries: #{retry_count}"
  end

  desc "Continuously dispatch due reminders and retries"
  task dispatch_loop: :environment do
    ActiveJob::Base.queue_adapter = :inline

    interval = ENV.fetch("REMINDER_DISPATCH_INTERVAL", "60").to_i.clamp(10, 3600)
    birthday_interval = ENV.fetch("BIRTHDAY_DISPATCH_INTERVAL", "900").to_i.clamp(60, 3600)
    last_birthday_dispatch_at = nil
    stop = false

    Signal.trap("TERM") { stop = true }
    Signal.trap("INT") { stop = true }

    until stop
      started_at = Time.current
      NotificationDispatcher.dispatch_all

      if last_birthday_dispatch_at.nil? || started_at - last_birthday_dispatch_at >= birthday_interval
        BirthdayGreetingDispatchJob.perform_now(started_at)
        last_birthday_dispatch_at = started_at
      end

      Rails.logger.info("reminders.dispatch_loop completed at #{started_at.iso8601}")
      sleep interval unless stop
    end
  end
end
