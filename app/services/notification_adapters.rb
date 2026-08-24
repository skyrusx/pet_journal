require "json"
require "net/http"
require "securerandom"

module NotificationAdapters
  def self.for(channel)
    case channel.channel_type
    when "email" then Email.new(channel)
    when "telegram" then Telegram.new(channel)
    when "vk" then Vk.new(channel)
    when "web_push" then WebPush.new(channel)
    else raise "Неизвестный канал уведомлений"
    end
  end

  class Base
    def initialize(channel)
      @channel = channel
    end

    private

    attr_reader :channel

    def reminder_text(reminder)
      [
        "PetJournal: #{reminder.title}",
        "Питомец: #{reminder.pet.name}",
        "Тип: #{reminder.reminder_type_label}",
        "Время: #{I18n.l(reminder.next_run_at)}",
        reminder.note.presence
      ].compact.join("\n")
    end
  end

  class Email < Base
    def deliver(delivery)
      ReminderMailer.due_reminder(delivery.reminder, channel).deliver_now
    end
  end

  class Telegram < Base
    def deliver(delivery)
      NotificationChannelConnectors::TelegramBot.send_message(
        chat_id: channel.address,
        text: reminder_text(delivery.reminder)
      )
    end
  end

  class Vk < Base
    VK_ENDPOINT = "https://api.vk.com/method/messages.send".freeze

    def deliver(delivery)
      token = ENV.fetch("VK_GROUP_TOKEN")
      response = Net::HTTP.post_form(URI(VK_ENDPOINT), {
        access_token: token,
        peer_id: channel.address,
        random_id: SecureRandom.random_number(2_147_483_647),
        message: reminder_text(delivery.reminder),
        v: ENV.fetch("VK_API_VERSION", "5.199")
      })
      body = JSON.parse(response.body)
      raise body["error"]["error_msg"] if body["error"].present?
    end
  end

  class WebPush < Base
    def deliver(delivery)
      require "webpush"

      reminder = delivery.reminder
      payload = {
        title: "PetJournal",
        body: "#{reminder.pet.name}: #{reminder.title}",
        path: Rails.application.routes.url_helpers.reminders_overview_path(pet_id: reminder.pet_id),
        tag: "reminder-#{reminder.id}"
      }

      ::Webpush.payload_send(
        message: payload.to_json,
        endpoint: channel.settings.fetch("endpoint"),
        p256dh: channel.settings.fetch("p256dh"),
        auth: channel.settings.fetch("auth"),
        ttl: 3_600,
        urgency: "high",
        vapid: WebPushConfiguration.vapid_options
      )
    rescue ::Webpush::InvalidSubscription
      invalidate_subscription!
      raise
    end

    private

    def invalidate_subscription!
      channel.update!(
        enabled: false,
        verified_at: nil,
        settings: channel.settings.merge("invalidated_at" => Time.current.iso8601)
      )
    end
  end
end
