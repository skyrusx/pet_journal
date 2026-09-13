require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirects guests to login" do
    get admin_root_path

    assert_redirected_to new_user_session_path
  end

  test "rejects regular users" do
    sign_in users(:one)

    get admin_root_path

    assert_redirected_to root_path
    assert_equal "У вас нет доступа к разделу управления.", flash[:alert]
  end

  test "allows admins" do
    sign_in users(:admin)

    get admin_root_path

    assert_response :success
    assert_select "h1", "Обзор"
  end

  test "renders mobile admin chrome" do
    sign_in users(:admin)

    get admin_root_path

    assert_response :success
    assert_select "header.admin-mobile-chrome__header"
    assert_select "nav.admin-mobile-tabs"
    assert_select "nav.admin-mobile-tabs a", text: /Обзор/
    assert_select "nav.admin-mobile-tabs a", text: /Пользователи/
    assert_select "nav.admin-mobile-tabs a", text: /Питомцы/
    assert_select "nav.admin-mobile-tabs a", text: /PetJournal/
  end

  test "links dashboard metrics to matching admin catalogs" do
    sign_in users(:admin)

    get admin_root_path

    assert_response :success
    assert_select "a.admin-metric-card[href*='registered=7_days'][href*='role=user']"
    assert_select "a.admin-metric-card[href*='created=7_days'][href*='owner_role=user']"
    assert_select "a.admin-usage-item[href*='usage=with_pet']"
    assert_select "a.admin-attention-item[href*='lost=1'][href*='owner_role=user']"
  end
end
