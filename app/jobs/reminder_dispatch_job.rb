class ReminderDispatchJob < ApplicationJob
  queue_as :default

  def perform
    NotificationDispatcher.dispatch_due
  end
end
