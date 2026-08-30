require "application_system_test_case"

class ReleaseCoreFlowTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
  end

  test "owner can move from login to pet first journal entry and reminder" do
    sign_in_through_ui
    assert_selector "[data-dashboard-root]", visible: true

    visit new_pet_path
    fill_in "pet_name", with: "Релизный питомец"
    fill_in "pet_species", with: "Кот"
    click_button "Сохранить"

    pet = Pet.find_by!(user: @user, name: "Релизный питомец")
    assert_current_path pet_path(pet)
    assert_text "Релизный питомец"
    assert_selector ".pj-pet-summary-card", count: 2

    click_link "Добавить запись", match: :first
    assert_current_path new_pet_pet_event_path(pet)
    click_button "Далее"
    fill_in "pet_event_title", with: "Первое наблюдение"
    click_button "Далее"
    click_button "Сохранить"

    event = pet.pet_events.find_by!(title: "Первое наблюдение")
    assert_current_path pet_pet_event_path(pet, event)
    assert_text "Первое наблюдение"

    visit pet_pet_events_path(pet)
    assert_text "Первое наблюдение"

    visit new_pet_reminder_path(pet)
    fill_in "reminder_title", with: "Проверить самочувствие"
    select "Лекарство", from: "reminder_reminder_type"
    click_button "Сохранить"

    assert_current_path reminders_overview_path(pet_id: pet.id)
    assert_text "Проверить самочувствие"
  end

  private

  def sign_in_through_ui
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password123"
    click_button "Войти"
    assert_current_path root_path
  end
end
