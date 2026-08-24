require "test_helper"

class NotificationChannelTest < ActiveSupport::TestCase
  test "email channel requires address" do
    channel = users(:one).notification_channels.new(channel_type: :email, name: "Почта")

    assert_not channel.valid?
    assert_includes channel.errors[:address], "не может быть пустым"
  end

  test "web push channel requires subscription settings" do
    channel = users(:one).notification_channels.new(channel_type: :web_push, name: "Браузер")

    assert_not channel.valid?
    assert_includes channel.errors[:settings], "не может быть пустым"
  end

  test "telegram channel reports unavailable bot" do
    channel = notification_channels(:telegram)
    channel.update!(enabled: true)

    assert_not channel.ready_for_delivery?
    assert_includes channel.configuration_issues, "Telegram пока в разработке и недоступен для подключения."
  end

  test "email channel is ready when address is present" do
    channel = notification_channels(:email)

    assert channel.ready_for_delivery?
    assert_empty channel.configuration_issues
  end

  test "same destination cannot be added twice for one channel type" do
    existing = notification_channels(:email)
    duplicate = existing.user.notification_channels.new(
      channel_type: :email,
      name: "Дубликат",
      address: existing.address.upcase
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:address], "уже подключён для этого канала"
  end
end
