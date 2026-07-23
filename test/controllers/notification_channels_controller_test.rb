require "test_helper"

class NotificationChannelsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @channel = notification_channels(:email)
    sign_in @user
  end

  test "should get index" do
    get notification_channels_url

    assert_response :success
  end

  test "should create telegram channel" do
    assert_difference("NotificationChannel.count") do
      post notification_channels_url, params: {
        notification_channel: {
          channel_type: "telegram",
          name: "Telegram",
          address: "123456",
          enabled: "1"
        }
      }
    end

    assert_redirected_to notification_channels_url
  end

  test "should enqueue test delivery" do
    assert_enqueued_jobs 1 do
      post test_notification_channel_url(@channel)
    end

    assert_redirected_to notification_channels_url
  end
end
