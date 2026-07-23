require "test_helper"

class WebPushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:one)
  end

  test "should create web push channel from browser subscription" do
    assert_difference("NotificationChannel.channel_web_push.count") do
      post web_push_subscription_url, as: :json, params: {
        subscription: {
          endpoint: "https://push.example.test/subscription",
          keys: {
            p256dh: "public-key",
            auth: "auth-secret"
          }
        }
      }
    end

    assert_response :success
  end

  test "should destroy web push channel by endpoint" do
    channel = users(:one).notification_channels.create!(
      channel_type: :web_push,
      name: "Браузер",
      address: "https://push.example.test/to-delete",
      verified_at: Time.current,
      settings: {
        "endpoint" => "https://push.example.test/to-delete",
        "p256dh" => "public-key",
        "auth" => "auth-secret"
      }
    )

    assert_difference("NotificationChannel.count", -1) do
      delete web_push_subscription_url, as: :json, params: { endpoint: channel.address }
    end

    assert_response :success
  end
end
