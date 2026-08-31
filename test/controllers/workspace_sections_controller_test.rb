require "test_helper"

class WorkspaceSectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "journal overview renders cross-pet empty state when user has no pets" do
    @user.pets.destroy_all

    get journal_overview_url

    assert_response :success
    assert_select ".pj-journal-page"
    assert_select ".pj-journal-empty h2", text: "Журнал пока пуст"
  end

  test "reminders overview renders cross-pet empty state when user has no pets" do
    @user.pets.destroy_all

    get reminders_overview_url

    assert_response :success
    assert_select ".pj-reminders-page"
    assert_select ".pj-reminders-empty h2", text: "Напоминаний пока нет"
  end

  test "documents overview renders cross-pet empty state when user has no pets" do
    @user.pets.destroy_all

    get documents_overview_url

    assert_response :success
    assert_select ".pj-documents-page"
    assert_select ".pj-documents-empty h2", text: "Документов пока нет"
  end

  test "journal overview remains a cross-pet page when pets exist" do
    pet = @user.pets.first
    assert_not_nil pet

    get journal_overview_url

    assert_response :success
    assert_select ".pj-journal-pet-switcher", text: /Все питомцы/
    assert_select "a[href=?]", journal_overview_path(pet_id: pet.id), text: /#{Regexp.escape(pet.name)}/
  end
end
