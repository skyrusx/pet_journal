require "application_system_test_case"

class MobileNavigationTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @pet = pets(:one)
  end

  test "mobile navigation uses current chrome and sheets without horizontal overflow" do
    sign_in_through_ui

    [[360, 800], [375, 667], [375, 812], [390, 844], [412, 915], [430, 932]].each do |width, height|
      page.driver.browser.manage.window.resize_to(width, height)
      visit root_path

      assert_selector "[data-dashboard-mobile-chrome]", visible: true
      assert_selector ".pj-mobile-chrome__header", visible: true
      assert_selector ".pj-mobile-tabs", visible: true
      assert_no_selector "[data-dashboard-sidebar]", visible: true
      assert_no_horizontal_overflow

      find('[data-dashboard-sheet-toggle="add"]', visible: true).click
      add_sheet = find('[data-dashboard-sheet="add"].is-open', visible: true)
      add_sheet.assert_text "Запись в журнал"
      assert_no_horizontal_overflow

      wait_for_sheet_transition(add_sheet)
      find('[data-dashboard-sheet="add"] [data-dashboard-sheet-close]', visible: true).click
      assert_no_selector '[data-dashboard-sheet="add"].is-open', visible: true

      find('[data-dashboard-sheet-toggle="more"]', visible: true).click
      more_sheet = find('[data-dashboard-sheet="more"].is-open', visible: true)
      more_sheet.assert_text "Публичный доступ"
      more_sheet.assert_text "Профиль"
      more_sheet.assert_text "Настройки"
      assert_no_horizontal_overflow

      wait_for_sheet_transition(more_sheet)
      find('[data-dashboard-sheet="more"] [data-dashboard-sheet-close]', visible: true).click
      assert_no_selector '[data-dashboard-sheet="more"].is-open', visible: true
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
        assert_selector "[data-dashboard-mobile-chrome]", visible: true
        assert_selector ".pj-mobile-tabs", visible: true
        assert_no_horizontal_overflow
      end
    end
  end

  test "desktop keeps sidebar without mobile chrome" do
    sign_in_through_ui

    [[1024, 768], [1440, 900]].each do |width, height|
      page.driver.browser.manage.window.resize_to(width, height)
      visit root_path

      assert_selector "[data-dashboard-sidebar]", visible: true
      assert_no_selector "[data-dashboard-mobile-chrome]", visible: true
      assert_no_horizontal_overflow
    end
  end

  private

  def sign_in_through_ui
    visit new_user_session_path
    fill_in "user_email", with: @user.email
    fill_in "user_password", with: "password123"
    click_button "Войти"
    assert_current_path root_path
  end

  def wait_for_sheet_transition(sheet)
    transition_ms = page.driver.browser.execute_script(<<~JS, sheet.native)
      const style = window.getComputedStyle(arguments[0]);
      const toMs = (value) => value.trim().endsWith("ms") ? parseFloat(value) : parseFloat(value) * 1000;
      const durations = style.transitionDuration.split(",").map(toMs);
      const delays = style.transitionDelay.split(",").map(toMs);

      return Math.max(...durations.map((duration, index) => duration + (delays[index] || delays[0] || 0)));
    JS

    sleep((transition_ms + 50) / 1000.0) if transition_ms.positive?
  end

  def assert_no_horizontal_overflow
    overflow = page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
    assert_operator overflow, :<=, 1
  end
end
