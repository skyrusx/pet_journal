require "test_helper"

class ReminderTest < ActiveSupport::TestCase
  test "due returns active reminders that were not notified for current occurrence" do
    reminder = reminders(:one)

    assert_includes Reminder.due, reminder

    reminder.update!(last_notified_at: Time.current)

    assert_not_includes Reminder.due, reminder
  end

  test "complete moves recurring reminder to future occurrence" do
    reminder = reminders(:weekly)

    reminder.complete!

    assert reminder.status_active?
    assert reminder.next_run_at.future?
    assert_not_nil reminder.last_completed_at
    assert_nil reminder.last_notified_at
  end
end
