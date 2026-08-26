require "test_helper"

class TelegramWebhooksControllerTest < ActionDispatch::IntegrationTest
  test "links Telegram chat to PetJournal user from start token" do
    user = users(:one)
    token = TelegramConnectionToken.generate(user)
    chat_id = "987654321"

    assert_difference("NotificationChannel.count", 1) do
      NotificationChannelConnectors::TelegramBot.stub(:send_message, true) do
        post telegram_webhook_url,
             params: {
               message: {
                 text: "/start #{token}",
                 chat: { id: chat_id },
                 from: {
                   id: 12345,
                   username: "skyrusx",
                   first_name: "Руслан",
                   last_name: "Федотов"
                 }
               }
             },
             as: :json
      end
    end

    assert_response :success
    channel = user.notification_channels.find_by!(channel_type: :telegram, address: chat_id)
    assert channel.enabled?
    assert channel.verified?
    assert_equal "skyrusx", channel.settings["username"]
    assert_equal "Руслан Федотов", channel.settings["display_name"]
  end
end
