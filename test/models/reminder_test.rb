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

    assert_difference("ReminderCompletion.count") do
      reminder.complete!
    end

    assert reminder.status_active?
    assert reminder.next_run_at.future?
    assert_not_nil reminder.last_completed_at
    assert_nil reminder.last_notified_at
  end

  test "custom repeat moves by configured interval and unit" do
    reminder = reminders(:weekly)
    reminder.update!(repeat_rule: :custom, repeat_interval: 3, repeat_unit: :months, next_run_at: 1.day.from_now)

    assert_equal 3.months.from_now.to_date, reminder.next_occurrence_from(Time.current).to_date
    assert_equal "Каждые 3 месяца", reminder.repeat_rule_label
  end

  test "snooze updates next run and clears notification marker" do
    reminder = reminders(:one)
    snooze_until = 2.hours.from_now
    reminder.update!(last_notified_at: Time.current)

    reminder.snooze_until!(snooze_until)

    assert_in_delta snooze_until.to_i, reminder.reload.next_run_at.to_i, 2
    assert_nil reminder.last_notified_at
    assert reminder.status_active?
  end
end
