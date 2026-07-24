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
    assert_select ".filter-chip", text: /Все/
  end

  test "should filter deliveries by status" do
    get notification_channels_url(delivery_status: "pending")

    assert_response :success
    assert_select ".filter-chip.active", text: /В очереди/
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

  test "should run test delivery immediately" do
    assert_difference("NotificationDelivery.count") do
      post test_notification_channel_url(@channel)
    end

    assert_redirected_to notification_channels_url
    assert NotificationDelivery.order(:created_at).last.status_sent?
  end

  test "should show diagnostic when test delivery channel is not configured" do
    channel = notification_channels(:telegram)
    channel.update!(enabled: true)

    assert_difference("NotificationDelivery.count") do
      post test_notification_channel_url(channel)
    end

    assert_redirected_to notification_channels_url
    delivery = NotificationDelivery.order(:created_at).last
    assert delivery.status_skipped?
    assert_match "TELEGRAM_BOT_TOKEN", delivery.error_message
  end

  test "should retry failed delivery immediately" do
    delivery = notification_deliveries(:pending)
    delivery.update!(status: :failed, attempts_count: 1, error_message: "Ошибка")

    post retry_delivery_notification_channels_url(delivery_id: delivery)

    assert_redirected_to notification_channels_url(delivery_status: :sent)
    assert delivery.reload.status_sent?
  end

  test "should update notification quiet hours settings" do
    patch settings_notification_channels_url, params: {
      user: {
        notifications_quiet_hours_enabled: "1",
        notifications_quiet_hours_start: "21:30",
        notifications_quiet_hours_end: "07:15",
        notifications_time_zone: "Asia/Novokuznetsk"
      }
    }

    assert_redirected_to notification_channels_url
    @user.reload
    assert @user.notifications_quiet_hours_enabled?
    assert_equal "Asia/Novokuznetsk", @user.notifications_time_zone
  end
end
