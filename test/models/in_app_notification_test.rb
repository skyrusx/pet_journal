require "test_helper"

class InAppNotificationTest < ActiveSupport::TestCase
  test "creates one notification per reminder occurrence" do
    reminder = reminders(:one)

    assert_difference("InAppNotification.count", 1) do
      InAppNotification.for_reminder!(reminder)
    end

    assert_no_difference("InAppNotification.count") do
      InAppNotification.for_reminder!(reminder)
    end

    notification = reminder.user.in_app_notifications.order(:created_at).last
    assert_equal "reminder_due", notification.kind
    assert_equal "Пора: #{reminder.title}", notification.title
    assert_includes notification.body, reminder.pet.name
    assert_equal Rails.application.routes.url_helpers.pet_reminder_path(reminder.pet, reminder), notification.target_path
    assert_nil notification.read_at
  end

  test "marks notification as read only once" do
    notification = InAppNotification.for_reminder!(reminders(:one))

    notification.mark_read!
    first_read_at = notification.reload.read_at
    assert_not_nil first_read_at

    travel 1.minute do
      notification.mark_read!
      assert_equal first_read_at, notification.reload.read_at
    end
  end
end
