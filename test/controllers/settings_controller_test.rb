require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get settings" do
    get settings_url

    assert_response :success
    assert_select ".pj-settings-page"
    assert_select "input[name='user[interface_text_size]']", count: 3
    assert_select "select[name='user[notifications_time_zone]']"
  end

  test "should update interface and time zone settings" do
    patch settings_url, params: {
      user: {
        interface_text_size: "comfortable",
        notifications_time_zone: "Moscow"
      }
    }

    assert_redirected_to settings_url
    assert_equal "comfortable", @user.reload.interface_text_size
    assert_equal "Moscow", @user.notifications_time_zone
  end

  test "should reject unsupported interface size" do
    patch settings_url, params: {
      user: {
        interface_text_size: "giant",
        notifications_time_zone: "UTC"
      }
    }

    assert_response :unprocessable_entity
    assert_equal "standard", @user.reload.interface_text_size
  end
end
