require "application_system_test_case"

class MobileNavigationTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @pet = pets(:one)
  end

  test "mobile navigation uses compact header bottom nav and sheets without horizontal overflow" do
    sign_in_through_ui

    [[360, 800], [375, 667], [375, 812], [390, 844], [412, 915], [430, 932]].each do |width, height|
      page.driver.browser.manage.window.resize_to(width, height)
      visit root_path

      assert_selector ".mobile-app-header", visible: true
      assert_selector ".mobile-bottom-nav", visible: true
      assert_no_selector ".app-header-desktop", visible: true
      assert_no_horizontal_overflow

      click_button "Добавить"
      assert_selector "#mobile-add-sheet", visible: true
      assert_selector "#mobile-add-sheet", text: "Событие в журнал"
      assert_no_horizontal_overflow

      find("#mobile-add-sheet [data-mobile-sheet-close]").click
      click_button "Ещё"
      assert_selector "#mobile-more-sheet", visible: true
      assert_selector "#mobile-more-sheet", text: "Мои питомцы"
      assert_selector "#mobile-more-sheet", text: "PetTag"
      assert_selector "#mobile-more-sheet", text: "Настройки уведомлений"
      assert_no_horizontal_overflow
    end
  end

  test "critical authenticated pages fit common mobile widths" do
    sign_in_through_ui

    [[360, 800], [375, 667], [390, 844], [430, 932]].each do |width, height|
      page.driver.browser.manage.window.resize_to(width, height)

      [
        root_path,
        pet_path(@pet),
        pet_pet_events_path(@pet),
        pet_reminders_path(@pet),
        pet_pet_documents_path(@pet),
        pet_pet_tag_path(@pet)
      ].each do |path|
        visit path
        assert_selector ".mobile-bottom-nav", visible: true
        assert_no_horizontal_overflow
      end
    end
  end

  test "desktop keeps desktop navigation without mobile bottom nav" do
    sign_in_through_ui

    [[768, 1024], [1024, 768], [1440, 900]].each do |width, height|
      page.driver.browser.manage.window.resize_to(width, height)
      visit root_path

      assert_selector ".app-header-desktop", visible: true
      assert_no_selector ".mobile-bottom-nav", visible: true
      assert_no_horizontal_overflow
    end
  end

  private

  def sign_in_through_ui
    visit new_user_session_path
    fill_in "Электронная почта", with: @user.email
    fill_in "Пароль", with: "password123"
    click_button "Войти"
    assert_current_path root_path
  end

  def assert_no_horizontal_overflow
    overflow = page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
    assert_operator overflow, :<=, 1
  end
end
