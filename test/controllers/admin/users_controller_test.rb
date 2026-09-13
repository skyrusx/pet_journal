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

  test "shows user with access and usage details" do
    user = users(:one)
    user.external_identities.create!(
      provider: "vk",
      uid: "admin-user-test-vk",
      connected_at: Time.current,
      last_used_at: Time.current
    )

    get admin_user_path(user)

    assert_response :success
    assert_select "body", text: /#{Regexp.escape(user.email)}/
    assert_select "h2", text: "Доступ и роль"
    assert_select "body", text: /VK ID/
    assert_select "body", text: /Последняя активность/
    assert_select "a", text: /Питомцы пользователя/
  end

  test "admin can promote another user" do
    user = users(:one)

    patch admin_user_path(user), params: { user: { role: "admin" } }

    assert_redirected_to admin_user_path(user)
    assert user.reload.admin?
  end

  test "admin cannot demote own account" do
    admin = users(:admin)

    patch admin_user_path(admin), params: { user: { role: "user" } }

    assert_redirected_to admin_user_path(admin)
    assert admin.reload.admin?
    assert_equal "Нельзя снять роль администратора с текущего аккаунта.", flash[:alert]
  end
end
