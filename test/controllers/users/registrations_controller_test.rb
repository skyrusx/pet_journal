require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get redesigned profile page" do
    get edit_user_registration_url

    assert_response :success
    assert_select ".pj-account-page"
    assert_select "#pj-profile-form" do
      assert_select "input[type='submit'][value='Сохранить']", count: 1
    end
    assert_select "#pj-security-form" do
      assert_select "input[type='submit'][value='Сохранить']", count: 1
    end
    assert_select ".pj-account-profile-card .pj-account-card__kicker", text: "Основные данные"
    assert_select ".pj-account-profile-card h2", count: 0
    assert_select ".pj-account-security-card .pj-account-card__kicker", text: "Безопасность"
    assert_select ".pj-account-security-card h2", count: 0
    assert_select ".pj-account-danger-form button", text: "Удалить"
  end

  test "should update profile fields without current password" do
    put edit_user_registration_url, params: {
      user: {
        name: "Анна Петрова",
        phone: "+7 999 123-45-67"
      }
    }

    assert_redirected_to edit_user_registration_url
    @user.reload
    assert_equal "Анна Петрова", @user.name
    assert_equal "+7 999 123-45-67", @user.phone
  end

  test "should require current password when changing email" do
    put edit_user_registration_url, params: {
      user: {
        email: "new_owner@example.com",
        current_password: "wrong-password"
      }
    }

    assert_response :unprocessable_entity
    assert_equal "owner_one@example.com", @user.reload.email
  end

  test "should update email with current password" do
    put edit_user_registration_url, params: {
      user: {
        email: "new_owner@example.com",
        current_password: "password123"
      }
    }

    assert_redirected_to edit_user_registration_url
    assert_equal "new_owner@example.com", @user.reload.email
  end
end
