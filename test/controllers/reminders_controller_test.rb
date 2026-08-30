require "test_helper"

class RemindersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
    @reminder = reminders(:one)
    sign_in @user
  end

  test "should get global index for all pets" do
    second_pet = @user.pets.create!(name: "Луна")
    second_pet.reminders.create!(
      title: "Осмотр",
      reminder_type: :visit,
      remind_at: 2.days.from_now,
      repeat_rule: :once
    )

    get reminders_overview_url(status: "all")

    assert_response :success
    assert_select ".pj-reminders-pet-switcher", text: /Все питомцы/
    assert_select ".pj-reminders-row__pet", text: second_pet.name
  end

  test "should filter global index by pet" do
    get reminders_overview_url(pet_id: @pet.id, status: "all")

    assert_response :success
    assert_select ".pj-reminders-pet-switcher", text: /#{Regexp.escape(@pet.name)}/
    assert_select ".pj-reminders-row__pet", text: @pet.name
  end

  test "legacy nested index selects the requested pet" do
    get pet_reminders_url(@pet, status: "all")

    assert_response :success
    assert_select ".pj-reminders-pet-switcher", text: /#{Regexp.escape(@pet.name)}/
  end

  test "should show reminder" do
    get pet_reminder_url(@pet, @reminder)

    assert_response :success
    assert_select ".pj-reminder-detail-grid"
  end

  test "should get new with preset type" do
    get new_pet_reminder_url(@pet, type: "vaccination")

    assert_response :success
    assert_select "select[name='reminder[reminder_type]'] option[selected='selected']", text: /Вакцинация/
    assert_select "input[type='submit'][value='Сохранить']"
  end

  test "should get new with event prefill" do
    get new_pet_reminder_url(
      @pet,
      reminder: {
        title: "Повторный прием",
        reminder_type: "visit",
        remind_at: 1.week.from_now.change(sec: 0),
        note: "Создано из записи журнала."
      }
    )

    assert_response :success
    assert_select "input[name='reminder[title]'][value='Повторный прием']"
    assert_select "select[name='reminder[reminder_type]'] option[selected='selected']", text: /Визит/
    assert_select "textarea[name='reminder[note]']", text: /Создано из записи журнала/
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

    assert_redirected_to reminders_overview_url(pet_id: @pet.id)
  end

  test "interprets browser reminder time in the user's notification time zone" do
    @user.update!(notifications_time_zone: "Novosibirsk")
    title = "Лекарство по местному времени"

    travel_to Time.utc(2026, 8, 24, 15, 30) do
      post pet_reminders_url(@pet), params: {
        reminder: {
          title: title,
          reminder_type: "medication",
          remind_at: "2026-08-24T22:35",
          repeat_rule: "once"
        }
      }
    end

    reminder = @pet.reminders.find_by!(title: title)
    assert_equal Time.utc(2026, 8, 24, 15, 35), reminder.remind_at.utc
    assert_equal reminder.remind_at, reminder.next_run_at
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

    assert_redirected_to reminders_overview_url(pet_id: @pet.id)
    assert @reminder.reload.status_completed?
    assert @reminder.reminder_completions.last.pet_event.present?
  end

  test "should complete reminder without journal event" do
    assert_no_difference("PetEvent.count") do
      assert_difference("ReminderCompletion.count") do
        patch complete_pet_reminder_url(@pet, @reminder)
      end
    end

    assert_redirected_to reminders_overview_url(pet_id: @pet.id)
  end

  test "should snooze reminder" do
    patch snooze_pet_reminder_url(@pet, @reminder, preset: "hour")

    assert_redirected_to reminders_overview_url(pet_id: @pet.id)
    assert @reminder.reload.next_run_at.future?
  end

  test "should filter reminders by status" do
    get reminders_overview_url(pet_id: @pet.id, status: "overdue")

    assert_response :success
    assert_select "select[name='status'] option[selected='selected'][value='overdue']"
  end

  test "navigation badge matches the total number of active reminders" do
    @user.reminders.update_all(status: Reminder.statuses.fetch("completed"))
    @pet.reminders.create!(
      title: "Просроченное",
      reminder_type: :other,
      remind_at: 1.hour.ago,
      repeat_rule: :once
    )
    @pet.reminders.create!(
      title: "Будущее",
      reminder_type: :other,
      remind_at: 1.day.from_now,
      repeat_rule: :once
    )

    get reminders_overview_url(pet_id: @pet.id)

    assert_response :success
    assert_select ".pj-reminders-summary span", text: /2\s+активно/
    assert_select ".pj-dash-nav__badge", text: "2"
  end

  test "should progressively load reminders in batches of 25" do
    26.times do |index|
      @pet.reminders.create!(
        title: "Напоминание #{index + 1}",
        reminder_type: :other,
        remind_at: (index + 1).hours.from_now,
        repeat_rule: :once
      )
    end

    get reminders_overview_url(pet_id: @pet.id, status: "all")

    assert_response :success
    assert_select ".pj-reminders-row-wrap", count: 25
    assert_select ".pj-reminders-load-more", count: 1

    get reminders_overview_url(pet_id: @pet.id, status: "all", page: 2)

    assert_response :success
    assert_select ".pj-reminders-row-wrap", count: 28
    assert_select ".pj-reminders-load-more", count: 0
  end
end
