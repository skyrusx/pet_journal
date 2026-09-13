require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:admin)
  end

  test "lists users" do
    get admin_users_path

    assert_response :success
    assert_select "h1", "Пользователи"
    assert_select "body", text: /owner_one@example.com/
  end

  test "searches users by email" do
    get admin_users_path, params: { q: "owner_one" }

    assert_response :success
    assert_select "body", text: /owner_one@example.com/
    assert_select "body", text: /owner_two@example.com/, count: 0
  end

  test "shows user" do
    user = users(:one)

    get admin_user_path(user)

    assert_response :success
    assert_select "body", text: /#{Regexp.escape(user.email)}/
  end
end
