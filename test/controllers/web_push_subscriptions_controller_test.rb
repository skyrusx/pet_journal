require "test_helper"

class WebPushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should create web push channel from browser subscription" do
    WebPushConfiguration.stub(:configured?, true) do
      assert_difference("NotificationChannel.channel_web_push.count") do
        post_subscription(
          endpoint: "https://push.example.test/subscription",
          p256dh: "public-key",
          auth: "auth-secret"
        )
      end
    end

    assert_response :success
    channel = @user.notification_channels.channel_web_push.find_by!(address: "https://push.example.test/subscription")
    assert channel.enabled?
    assert channel.verified?
    assert_equal "public-key", channel.settings["p256dh"]
    assert_equal "auth-secret", channel.settings["auth"]
  end

  test "should update an existing subscription without creating a duplicate" do
    endpoint = "https://push.example.test/existing"

    channel = @user.notification_channels.create!(
      channel_type: :web_push,
      name: "Старый браузер",
      address: endpoint,
      enabled: false,
      settings: {
        "endpoint" => endpoint,
        "p256dh" => "old-key",
        "auth" => "old-auth",
        "invalidated_at" => 1.day.ago.iso8601
      }
    )

    WebPushConfiguration.stub(:configured?, true) do
      assert_no_difference("NotificationChannel.channel_web_push.count") do
        post_subscription(endpoint: endpoint, p256dh: "new-key", auth: "new-auth")
      end
    end

    assert_response :success
    channel.reload
    assert channel.enabled?
    assert channel.verified?
    assert_equal "new-key", channel.settings["p256dh"]
    assert_equal "new-auth", channel.settings["auth"]
    assert_nil channel.settings["invalidated_at"]
  end

  test "should reject incomplete browser subscription" do
    WebPushConfiguration.stub(:configured?, true) do
      assert_no_difference("NotificationChannel.channel_web_push.count") do
        post web_push_subscription_url, as: :json, params: {
          subscription: {
            endpoint: "https://push.example.test/incomplete",
            keys: { p256dh: "public-key" }
          }
        }
      end
    end

    assert_response :unprocessable_entity
  end

  test "should reject subscription when VAPID is not configured" do
    WebPushConfiguration.stub(:configured?, false) do
      assert_no_difference("NotificationChannel.channel_web_push.count") do
        post_subscription(
          endpoint: "https://push.example.test/no-vapid",
          p256dh: "public-key",
          auth: "auth-secret"
        )
      end
    end

    assert_response :service_unavailable
    assert_equal false, response.parsed_body["ok"]
  end

  test "should destroy web push channel by endpoint" do
    channel = @user.notification_channels.create!(
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

  test "should not destroy another users subscription" do
    other_user = User.create!(email: "push-owner@example.test", password: "password123")
    endpoint = "https://push.example.test/shared-endpoint"
    other_user.notification_channels.create!(
      channel_type: :web_push,
      name: "Другой браузер",
      address: endpoint,
      verified_at: Time.current,
      settings: {
        "endpoint" => endpoint,
        "p256dh" => "public-key",
        "auth" => "auth-secret"
      }
    )

    assert_no_difference("NotificationChannel.count") do
      delete web_push_subscription_url, as: :json, params: { endpoint: endpoint }
    end

    assert_response :success
  end

  private

  def post_subscription(endpoint:, p256dh:, auth:)
    post web_push_subscription_url, as: :json, params: {
      subscription: {
        endpoint: endpoint,
        keys: {
          p256dh: p256dh,
          auth: auth
        }
      }
    }
  end
end
