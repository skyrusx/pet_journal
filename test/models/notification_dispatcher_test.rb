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

  test "does not dispatch during quiet hours" do
    user = users(:one)
    user.update!(
      notifications_quiet_hours_enabled: true,
      notifications_quiet_hours_start: "22:00",
      notifications_quiet_hours_end: "08:00",
      notifications_time_zone: "UTC"
    )

    assert_no_enqueued_jobs do
      NotificationDispatcher.new(now: Time.zone.parse("2026-07-23 23:00")).dispatch_reminder(reminders(:one))
    end

    assert_nil reminders(:one).reload.last_notified_at
  end

  test "uses selected reminder channels only" do
    reminder = reminders(:one)
    reminder.notification_channels << notification_channels(:email)

    assert_enqueued_jobs 1 do
      NotificationDispatcher.new.dispatch_reminder(reminder)
    end
  end

  test "dispatches due retry deliveries" do
    delivery = notification_deliveries(:pending)
    delivery.update!(attempts_count: 1, next_attempt_at: 1.minute.ago)

    assert_enqueued_jobs 1 do
      NotificationDispatcher.dispatch_retries
    end
  end
end
