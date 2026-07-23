require "test_helper"

class NotificationDispatcherTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "dispatches due reminders once per scheduled occurrence" do
    reminder = reminders(:one)
    reminders(:weekly).update!(last_notified_at: Time.current)
    dispatcher = NotificationDispatcher.new

    assert_enqueued_jobs 1 do
      dispatcher.dispatch_reminder(reminder)
    end

    assert_not_nil reminder.reload.last_notified_at

    clear_enqueued_jobs

    assert_no_enqueued_jobs do
      NotificationDispatcher.dispatch_due
    end
  end
end
