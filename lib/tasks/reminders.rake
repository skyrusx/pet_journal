namespace :reminders do
  desc "Dispatch due reminders and retry pending failed deliveries"
  task dispatch: :environment do
    NotificationDispatcher.dispatch_all
  end

  desc "Retry pending failed notification deliveries"
  task retry_failed: :environment do
    NotificationDispatcher.dispatch_retries
  end
end
