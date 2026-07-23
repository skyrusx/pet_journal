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
end
