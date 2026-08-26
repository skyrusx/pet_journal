require "test_helper"

class PetEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
    @pet_event = pet_events(:one)
    sign_in @user
  end

  test "global journal opens without a pet id and defaults to all pets" do
    get journal_overview_url

    assert_response :success
    assert_select ".pj-journal-pet-switcher", text: /Все питомцы/
    assert_select ".pj-journal-row", minimum: 1
  end

  test "global journal can be filtered by one pet" do
    second_pet = @user.pets.create!(name: "Фрея", species: "Кошка")
    second_pet.pet_events.create!(
      event_type: :note,
      status: :completed,
      title: "Событие Фреи",
      event_date: Date.current
    )

    get journal_overview_url(pet_id: second_pet.id)

    assert_response :success
    assert_select ".pj-journal-pet-switcher", text: /Фрея/
    assert_select ".pj-journal-row", text: /Событие Фреи/
    assert_select ".pj-journal-row", text: /#{Regexp.escape(@pet_event.title)}/, count: 0
  end

  test "legacy nested journal index still renders the selected pet" do
    get pet_pet_events_url(@pet)

    assert_response :success
    assert_select ".pj-journal-pet-switcher", text: /#{Regexp.escape(@pet.name)}/
  end

  test "should filter journal by event type" do
    get journal_overview_url(type: "vaccination")

    assert_response :success
    assert_select ".pj-journal-row", minimum: 1
  end

  test "should ignore unknown event type filter" do
    get journal_overview_url(type: "unknown")

    assert_response :success
    assert_select ".pj-journal-row", minimum: 1
  end

  test "should search structured fields" do
    get journal_overview_url(q: "Nobivac")

    assert_response :success
    assert_select ".pj-journal-row", text: /MyString/
  end

  test "should filter journal by period" do
    get journal_overview_url(period: "year")

    assert_response :success
  end

  test "should filter journal by files marker" do
    get journal_overview_url(marker: "with_files")

    assert_response :success
  end

  test "should filter journal by follow up marker" do
    get journal_overview_url(marker: "follow_up")

    assert_response :success
  end

  test "journal progressively exposes twenty five events at a time" do
    26.times do |index|
      @pet.pet_events.create!(
        event_type: :note,
        status: :completed,
        title: "Запись #{index}",
        event_date: Date.current - index.days
      )
    end

    get journal_overview_url(pet_id: @pet.id)

    assert_response :success
    assert_select ".pj-journal-load-more__button", text: /Показать ещё/

    get journal_overview_url(pet_id: @pet.id, page: 2)

    assert_response :success
    assert_select ".pj-journal-load-more__button", count: 0
  end

  test "should show event" do
    get pet_pet_event_url(@pet, @pet_event)

    assert_response :success
  end

  test "should get new" do
    get new_pet_pet_event_url(@pet)

    assert_response :success
  end

  test "should create event" do
    assert_difference("PetEvent.count") do
      post pet_pet_events_url(@pet), params: {
        pet_event: {
          event_type: "note",
          status: "completed",
          title: "Новая заметка",
          event_date: Date.current,
          description: "Тестовая запись"
        }
      }
    end

    assert_redirected_to pet_pet_event_url(@pet, PetEvent.order(:created_at).last)
  end

  test "should create weight event and update pet weight" do
    post pet_pet_events_url(@pet), params: {
      pet_event: {
        event_type: "weight",
        status: "completed",
        title: "Контроль веса",
        event_date: Date.current,
        weight_value: 5.7,
        weight_unit: "kg"
      }
    }

    assert_redirected_to pet_pet_event_url(@pet, PetEvent.order(:created_at).last)
    assert_equal BigDecimal("5.7"), @pet.reload.weight
  end

  test "should create follow up reminder from structured event" do
    assert_difference("Reminder.count") do
      post pet_pet_events_url(@pet), params: {
        create_follow_up_reminder: "1",
        pet_event: {
          event_type: "visit",
          status: "completed",
          title: "Повторный прием",
          event_date: Date.current,
          clinic_name: "Good Vet",
          next_action_at: 1.week.from_now
        }
      }
    end

    event = PetEvent.order(:created_at).last
    assert_redirected_to pet_pet_event_url(@pet, event)
    reminder = Reminder.order(:created_at).last
    assert_equal "Повторить: Повторный прием", reminder.title
    assert_equal "visit", reminder.reminder_type
    assert_equal "Создано из события журнала от #{event.event_date.strftime('%d.%m.%Y')}.", reminder.note
  end

  test "should get edit" do
    get edit_pet_pet_event_url(@pet, @pet_event)

    assert_response :success
  end

  test "should update event" do
    patch pet_pet_event_url(@pet, @pet_event), params: {
      pet_event: {
        title: "Обновленное событие",
        event_type: @pet_event.event_type,
        status: @pet_event.status,
        event_date: @pet_event.event_date,
        description: @pet_event.description
      }
    }

    assert_redirected_to pet_pet_event_url(@pet, @pet_event)
    assert_equal "Обновленное событие", @pet_event.reload.title
  end

  test "destroy redirects back to the global journal with pet filter" do
    assert_difference("PetEvent.count", -1) do
      delete pet_pet_event_url(@pet, @pet_event)
    end

    assert_redirected_to journal_overview_url(pet_id: @pet.id)
  end
end
