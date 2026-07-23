namespace :reminders do
  desc "Dispatch due reminders to configured notification channels"
  task dispatch: :environment do
    NotificationDispatcher.dispatch_due
  end
end
