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
    assert_equal Rails.application.routes.url_helpers.reminders_overview_path(pet_id: reminder.pet_id), payload["path"]
    assert_equal "reminder-#{reminder.id}", payload["tag"]
  end
end
