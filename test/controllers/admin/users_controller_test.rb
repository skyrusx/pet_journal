require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @admin.update!(admin: true)
  end

  test "regular user cannot open users section" do
    sign_in users(:two)

    get admin_users_url

    assert_redirected_to root_path
  end

  test "admin can open users list" do
    sign_in @admin

    get admin_users_url

    assert_response :success
    assert_select ".admin-users-table"
    assert_select ".admin-users-mobile-list"
    assert_select "a[href=?]", admin_user_path(users(:two)), minimum: 1
  end

  test "admin can search users" do
    sign_in @admin

    get admin_users_url, params: { q: users(:two).email }

    assert_response :success
    assert_select ".admin-users-table tbody tr", count: 1
    assert_select ".admin-users-table", text: /#{Regexp.escape(users(:two).email)}/
  end

  test "admin can open user details" do
    sign_in @admin

    get admin_user_url(users(:two))

    assert_response :success
    assert_select ".admin-user-profile-card", text: /#{Regexp.escape(users(:two).email)}/
    assert_select ".admin-user-detail-grid"
  end
end
