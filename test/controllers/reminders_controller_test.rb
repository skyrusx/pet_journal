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
    assert_select ".reminders-hero"
    assert_select ".reminders-filter-panel"
    assert_select ".reminders-metrics > div", count: 6
  end

  test "should show reminder" do
    get pet_reminder_url(@pet, @reminder)

    assert_response :success
    assert_select ".reminder-detail-page"
    assert_select ".reminders-metrics > div", count: 6
  end

  test "should get new with preset type" do
    get new_pet_reminder_url(@pet, type: "vaccination")

    assert_response :success
    assert_select "select[name='reminder[reminder_type]'] option[selected='selected']", text: /Прививка/
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
    assert_difference(["PetEvent.count", "ReminderCompletion.count"]) do
      patch complete_pet_reminder_url(@pet, @reminder, create_event: "1")
    end

    assert_redirected_to pet_reminders_url(@pet)
    assert @reminder.reload.status_completed?
    assert @reminder.reminder_completions.last.pet_event.present?
  end

  test "should complete reminder without journal event" do
    assert_no_difference("PetEvent.count") do
      assert_difference("ReminderCompletion.count") do
        patch complete_pet_reminder_url(@pet, @reminder)
      end
    end

    assert_redirected_to pet_reminders_url(@pet)
  end

  test "should snooze reminder" do
    patch snooze_pet_reminder_url(@pet, @reminder, preset: "hour")

    assert_redirected_to pet_reminders_url(@pet)
    assert @reminder.reload.next_run_at.future?
  end

  test "should filter reminders by status" do
    get pet_reminders_url(@pet, status: "overdue")

    assert_response :success
    assert_select ".filter-chip.active", text: /Просроченные/
  end
end
