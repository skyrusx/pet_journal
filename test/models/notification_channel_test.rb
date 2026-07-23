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
end
