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
    USER_PERMISSION_ERROR_CODE = 901

    def deliver(delivery)
      token = VkConfiguration.group_token
      raise "VK-уведомления временно недоступны. Попробуйте позже." if token.blank?

      response = Net::HTTP.post_form(URI(VK_ENDPOINT), {
        access_token: token,
        peer_id: channel.address,
        random_id: SecureRandom.random_number(2_147_483_647),
        message: reminder_text(delivery.reminder),
        v: VkConfiguration.api_version
      })
      body = JSON.parse(response.body)
      handle_vk_error!(body["error"]) if body["error"].present?
    end

    private

    def handle_vk_error!(error)
      code = error["error_code"].to_i
      technical_message = error["error_msg"].to_s
      Rails.logger.warn("VK notification delivery failed (#{code}): #{technical_message}")

      message = case code
      when USER_PERMISSION_ERROR_CODE
        "Чтобы получать уведомления VK, сначала разрешите сообщения от PetJournal: откройте сообщество со своего профиля и отправьте ему любое сообщение. Затем повторите тест."
      when 5
        "VK-уведомления временно недоступны. Попробуйте позже."
      when 100, 113
        "Не удалось определить получателя VK. Переподключите VK-канал и повторите попытку."
      else
        "VK не смог отправить уведомление. Проверьте, что сообщения сообщества разрешены для вашего профиля, и повторите попытку."
      end

      raise message
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
    rescue ::Webpush::ExpiredSubscription, ::Webpush::InvalidSubscription
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
