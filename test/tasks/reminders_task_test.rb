require "test_helper"
require "rake"

class RemindersTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  test "dispatch task sends due reminder deliveries inline" do
    reminder = reminders(:one)
    Reminder.where.not(id: reminder.id).update_all(last_notified_at: Time.current)
    reminder.notification_channels << notification_channels(:email)
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :inline

    assert_difference("NotificationDelivery.status_sent.count") do
      Rake::Task["reminders:dispatch"].reenable
      Rake::Task["reminders:dispatch"].invoke
    end

    assert_not_nil reminder.reload.last_notified_at
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter if defined?(previous_adapter)
  end
end
