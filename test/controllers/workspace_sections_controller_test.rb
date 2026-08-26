require "test_helper"

class WorkspaceSectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "renders journal empty state when user has no pets" do
    @user.pets.destroy_all

    get journal_overview_url

    assert_response :success
    assert_select ".pj-section-empty-page--journal"
    assert_select "h2", text: "Журнал пока пуст"
    assert_select "a", text: "Добавить питомца"
  end

  test "renders reminders empty state when user has no pets" do
    @user.pets.destroy_all

    get reminders_overview_url

    assert_response :success
    assert_select ".pj-section-empty-page--reminders"
    assert_select "h2", text: "Нет напоминаний"
  end

  test "renders documents empty state when user has no pets" do
    @user.pets.destroy_all

    get documents_overview_url

    assert_response :success
    assert_select ".pj-section-empty-page--documents"
    assert_select "h2", text: "Документы отсутствуют"
  end

  test "journal overview forwards to pet journal when pet exists" do
    pet = @user.pets.first

    get journal_overview_url

    assert_redirected_to pet_pet_events_url(pet)
  end
end
