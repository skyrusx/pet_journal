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
    assert_select ".pj-notifications-section", text: /Подключённые каналы/
    assert_select "select[name='delivery_status'] option[value='all'][selected]"
  end

  test "should filter deliveries by status" do
    get notification_channels_url(delivery_status: "pending")

    assert_response :success
    assert_select "select[name='delivery_status'] option[value='pending'][selected]"
  end

  test "should progressively load delivery history" do
    reminder = reminders(:one)
    30.times do
      NotificationDelivery.create!(
        reminder: reminder,
        notification_channel: @channel,
        status: :sent,
        attempts_count: 1,
        delivered_at: Time.current
      )
    end

    get notification_channels_url(delivery_status: "sent")

    assert_response :success
    assert_select ".pj-notifications-delivery-row", NotificationChannelsController::DELIVERY_PAGE_SIZE
    assert_select ".pj-notifications-load-more__button", text: /Показать ещё/

    get notification_channels_url(delivery_status: "sent", page: 2)

    assert_response :success
    assert_select ".pj-notifications-delivery-row", 30
    assert_select ".pj-notifications-load-more__button", count: 0
  end

  test "should show Telegram as disabled while bot is not configured" do
    TelegramConfiguration.stub(:configured?, false) do
      get new_notification_channel_url
    end

    assert_response :success
    assert_select "select[name='notification_channel[channel_type]'] option[value='telegram'][disabled]", text: /Telegram — в разработке/
  end

  test "should not create Telegram channel while bot is not configured" do
    TelegramConfiguration.stub(:configured?, false) do
      assert_no_difference("NotificationChannel.count") do
        post notification_channels_url, params: {
          notification_channel: {
            channel_type: "telegram",
            name: "Telegram",
            address: "123456",
            enabled: "1"
          }
        }
      end
    end

    assert_response :unprocessable_entity
    assert_select ".pj-notifications-form-errors", text: /Telegram пока в разработке/
  end

  test "should resolve friendly VK profile when creating channel" do
    result = NotificationChannelConnectors::VkProfileResolver::Result.new(
      user_id: "123456",
      screen_name: "skyrusx",
      display_name: "Руслан Федотов"
    )

    NotificationChannelConnectors::VkProfileResolver.stub(:call, result) do
      assert_difference("NotificationChannel.count") do
        post notification_channels_url, params: {
          notification_channel: {
            channel_type: "vk",
            name: "VK",
            address: "https://vk.ru/skyrusx",
            enabled: "1"
          }
        }
      end
    end

    assert_redirected_to notification_channels_url
    channel = @user.notification_channels.order(:created_at).last
    assert channel.channel_vk?
    assert_equal "123456", channel.address
    assert_equal "skyrusx", channel.settings["screen_name"]
    assert_equal "Руслан Федотов", channel.settings["display_name"]
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

    TelegramConfiguration.stub(:configured?, false) do
      assert_difference("NotificationDelivery.count") do
        post test_notification_channel_url(channel)
      end
    end

    assert_redirected_to notification_channels_url
    delivery = NotificationDelivery.order(:created_at).last
    assert delivery.status_skipped?
    assert_match "Telegram пока в разработке", delivery.error_message
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
        notifications_time_zone: "Novosibirsk"
      }
    }

    assert_redirected_to notification_channels_url
    @user.reload
    assert @user.notifications_quiet_hours_enabled?
    assert_equal "Novosibirsk", @user.notifications_time_zone
  end
end
