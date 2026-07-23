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
    TELEGRAM_ENDPOINT = "https://api.telegram.org/bot".freeze

    def deliver(delivery)
      token = ENV.fetch("TELEGRAM_BOT_TOKEN")
      uri = URI("#{TELEGRAM_ENDPOINT}#{token}/sendMessage")
      post_json(uri, chat_id: channel.address, text: reminder_text(delivery.reminder))
    end

    private

    def post_json(uri, payload)
      response = Net::HTTP.post(uri, payload.to_json, "Content-Type" => "application/json")
      raise response.body unless response.is_a?(Net::HTTPSuccess)
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

      vapid_public_key = ENV.fetch("VAPID_PUBLIC_KEY")
      vapid_private_key = ENV.fetch("VAPID_PRIVATE_KEY")
      payload = {
        title: "PetJournal",
        body: "#{delivery.reminder.pet.name}: #{delivery.reminder.title}",
        path: Rails.application.routes.url_helpers.pet_reminders_path(delivery.reminder.pet)
      }

      ::WebPush.payload_send(
        message: payload.to_json,
        endpoint: channel.settings.fetch("endpoint"),
        p256dh: channel.settings.fetch("p256dh"),
        auth: channel.settings.fetch("auth"),
        vapid: {
          subject: ENV.fetch("VAPID_SUBJECT", "mailto:#{delivery.reminder.user.email}"),
          public_key: vapid_public_key,
          private_key: vapid_private_key
        }
      )
    end
  end
end
