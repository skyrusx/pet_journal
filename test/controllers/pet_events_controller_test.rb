require "test_helper"

class PetEventsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @pet = pets(:one)
    @pet_event = pet_events(:one)
    sign_in @user
  end

  test "should get index" do
    get pet_pet_events_url(@pet)

    assert_response :success
  end

  test "should filter index by event type" do
    get pet_pet_events_url(@pet, type: "vaccination")

    assert_response :success
    assert_select ".filter-chip.active", text: /Прививка/
  end

  test "should ignore unknown event type filter" do
    get pet_pet_events_url(@pet, type: "unknown")

    assert_response :success
    assert_select ".filter-chip.active", text: /Все/
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
          title: "Новая заметка",
          event_date: Date.current,
          description: "Тестовая запись"
        }
      }
    end

    assert_redirected_to pet_pet_event_url(@pet, PetEvent.order(:created_at).last)
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
        event_date: @pet_event.event_date,
        description: @pet_event.description
      }
    }

    assert_redirected_to pet_pet_event_url(@pet, @pet_event)
    assert_equal "Обновленное событие", @pet_event.reload.title
  end

  test "should destroy event" do
    assert_difference("PetEvent.count", -1) do
      delete pet_pet_event_url(@pet, @pet_event)
    end

    assert_redirected_to pet_pet_events_url(@pet)
  end
end
