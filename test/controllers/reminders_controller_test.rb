require "test_helper"

class RemindersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
    @reminder = reminders(:one)
    sign_in @user
  end

  test "should get index" do
    get pet_reminders_url(@pet)

    assert_response :success
  end

  test "should create reminder" do
    assert_difference("Reminder.count") do
      post pet_reminders_url(@pet), params: {
        reminder: {
          title: "Прививка",
          reminder_type: "vaccination",
          remind_at: 1.day.from_now,
          repeat_rule: "once",
          note: "В клинике"
        }
      }
    end

    assert_redirected_to pet_reminders_url(@pet)
  end

  test "should create reminder with selected channels" do
    assert_difference("ReminderNotificationChannel.count") do
      post pet_reminders_url(@pet), params: {
        reminder: {
          title: "Визит",
          reminder_type: "visit",
          remind_at: 2.days.from_now,
          repeat_rule: "once",
          notification_channel_ids: [notification_channels(:email).id]
        }
      }
    end

    reminder = Reminder.order(:created_at).last
    assert_equal [notification_channels(:email)], reminder.notification_channels.to_a
  end

  test "should complete reminder and create journal event" do
    assert_difference("PetEvent.count") do
      patch complete_pet_reminder_url(@pet, @reminder, create_event: "1")
    end

    assert_redirected_to pet_reminders_url(@pet)
    assert @reminder.reload.status_completed?
  end
end
