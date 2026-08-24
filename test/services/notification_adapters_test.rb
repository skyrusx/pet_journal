require "test_helper"
require "webpush"

class NotificationAdaptersTest < ActiveSupport::TestCase
  test "web push adapter sends reminder through Webpush with VAPID" do
    user = users(:one)
    reminder = reminders(:one)
    endpoint = "https://push.example.test/adapter"
    channel = user.notification_channels.create!(
      channel_type: :web_push,
      name: "Тестовый браузер",
      address: endpoint,
      enabled: true,
      verified_at: Time.current,
      settings: {
        "endpoint" => endpoint,
        "p256dh" => "browser-public-key",
        "auth" => "browser-auth"
      }
    )
    delivery = reminder.notification_deliveries.create!(notification_channel: channel)
    sent_options = nil
    vapid = {
      subject: "mailto:support@pet-journal.ru",
      public_key: "vapid-public",
      private_key: "vapid-private"
    }

    WebPushConfiguration.stub(:vapid_options, vapid) do
      Webpush.stub(:payload_send, ->(**options) { sent_options = options }) do
        NotificationAdapters.for(channel).deliver(delivery)
      end
    end

    assert_equal endpoint, sent_options[:endpoint]
    assert_equal "browser-public-key", sent_options[:p256dh]
    assert_equal "browser-auth", sent_options[:auth]
    assert_equal vapid, sent_options[:vapid]
    assert_equal 3_600, sent_options[:ttl]
    assert_equal "high", sent_options[:urgency]

    payload = JSON.parse(sent_options[:message])
    assert_equal "PetJournal", payload["title"]
    assert_includes payload["body"], reminder.pet.name
    assert_equal Rails.application.routes.url_helpers.pet_reminder_path(reminder.pet, reminder), payload["path"]
    assert_equal "reminder-#{reminder.id}", payload["tag"]
    assert_equal reminder.next_run_at.to_i * 1000, payload["timestamp"]
    assert_equal true, payload["require_interaction"]
  end

  test "VK adapter sends polished reminder with inline open button for public host" do
    user = users(:one)
    reminder = reminders(:one)
    channel = user.notification_channels.create!(
      channel_type: :vk,
      name: "VK",
      address: "123456",
      enabled: true
    )
    delivery = reminder.notification_deliveries.create!(notification_channel: channel)
    submitted = nil
    response = Struct.new(:body).new({ response: 1 }.to_json)

    VkConfiguration.stub(:group_token, "credential-token") do
      VkConfiguration.stub(:api_version, "5.199") do
        Net::HTTP.stub(:post_form, ->(uri, params) { submitted = [uri, params]; response }) do
          NotificationAdapters.for(channel).deliver(delivery)
        end
      end
    end

    uri, params = submitted
    assert_equal "https://api.vk.com/method/messages.send", uri.to_s
    assert_equal "credential-token", params[:access_token]
    assert_equal "123456", params[:peer_id]
    assert_equal "5.199", params[:v]
    assert_includes params[:message], "🐾 PetJournal"
    assert_includes params[:message], "Пора: #{reminder.title}"
    assert_includes params[:message], reminder.pet.name
    assert_includes params[:message], reminder.reminder_type_label
    assert_includes params[:message], reminder.note

    keyboard = JSON.parse(params[:keyboard])
    action = keyboard.dig("buttons", 0, 0, "action")
    assert_equal true, keyboard["inline"]
    assert_equal "open_link", action["type"]
    assert_equal "Открыть напоминание", action["label"]
    assert_includes action["link"], "/pets/#{reminder.pet_id}/reminders/#{reminder.id}"
  end

  test "VK adapter omits open button for localhost but still sends reminder" do
    user = users(:one)
    reminder = reminders(:one)
    channel = user.notification_channels.create!(
      channel_type: :vk,
      name: "ВКонтакте localhost",
      address: "654321",
      enabled: true
    )
    delivery = reminder.notification_deliveries.create!(notification_channel: channel)
    submitted = nil
    response = Struct.new(:body).new({ response: 1 }.to_json)
    original_options = Rails.application.config.action_mailer.default_url_options

    Rails.application.config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

    VkConfiguration.stub(:group_token, "credential-token") do
      Net::HTTP.stub(:post_form, ->(_uri, params) { submitted = params; response }) do
        NotificationAdapters.for(channel).deliver(delivery)
      end
    end

    assert_includes submitted[:message], "🐾 PetJournal"
    assert_nil submitted[:keyboard]
  ensure
    Rails.application.config.action_mailer.default_url_options = original_options
  end

  test "VK adapter sends a dedicated test message without old reminder data" do
    user = users(:one)
    reminder = reminders(:one)
    channel = user.notification_channels.create!(
      channel_type: :vk,
      name: "VK",
      address: "123456",
      enabled: true
    )
    delivery = reminder.notification_deliveries.create!(notification_channel: channel)
    submitted = nil
    response = Struct.new(:body).new({ response: 1 }.to_json)

    VkConfiguration.stub(:group_token, "credential-token") do
      Net::HTTP.stub(:post_form, ->(_uri, params) { submitted = params; response }) do
        NotificationAdapters.for(channel).deliver(delivery, test_delivery: true)
      end
    end

    assert_includes submitted[:message], "✅ VK подключён"
    assert_includes submitted[:message], "Тестовое уведомление PetJournal успешно доставлено"
    assert_not_includes submitted[:message], reminder.title
    assert_not_includes submitted[:message], reminder.note
    assert_nil submitted[:keyboard]
  end

  test "VK adapter explains when user has not allowed community messages" do
    user = users(:one)
    reminder = reminders(:one)
    channel = user.notification_channels.create!(
      channel_type: :vk,
      name: "VK",
      address: "123456",
      enabled: true
    )
    delivery = reminder.notification_deliveries.create!(notification_channel: channel)
    response = Struct.new(:body).new({
      error: {
        error_code: 901,
        error_msg: "Can't send messages for users without permission"
      }
    }.to_json)

    error = assert_raises(RuntimeError) do
      VkConfiguration.stub(:group_token, "credential-token") do
        Net::HTTP.stub(:post_form, response) do
          NotificationAdapters.for(channel).deliver(delivery)
        end
      end
    end

    assert_includes error.message, "сначала разрешите сообщения от PetJournal"
    assert_includes error.message, "отправьте ему любое сообщение"
    assert_not_includes error.message, "Can't send messages"
  end
end
