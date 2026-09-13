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
end
