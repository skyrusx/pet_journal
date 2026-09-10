require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "guest is redirected to sign in" do
    get admin_root_url

    assert_redirected_to new_user_session_path
  end

  test "regular user cannot open admin" do
    sign_in users(:one)

    get admin_root_url

    assert_redirected_to root_path
    assert_equal "У вас нет доступа к разделу управления.", flash[:alert]
  end

  test "admin can open dashboard" do
    admin = users(:one)
    admin.update!(admin: true)
    sign_in admin

    get admin_root_url

    assert_response :success
    assert_select "body.admin-body"
    assert_select ".admin-sidebar a[href=?]", admin_root_path, text: /Обзор/
    assert_select ".admin-sidebar a[href=?]", admin_users_path, text: /Пользователи/
    assert_select ".admin-stat-card", count: 3
    assert_select ".admin-mobile-bottom-nav"
  end
end
