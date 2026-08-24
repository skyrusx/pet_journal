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
    def deliver(delivery, test_delivery: false)
      ReminderMailer.due_reminder(delivery.reminder, channel).deliver_now
    end
  end

  class Telegram < Base
    def deliver(delivery, test_delivery: false)
      NotificationChannelConnectors::TelegramBot.send_message(
        chat_id: channel.address,
        text: reminder_text(delivery.reminder)
      )
    end
  end

  class Vk < Base
    VK_ENDPOINT = "https://api.vk.com/method/messages.send".freeze
    USER_PERMISSION_ERROR_CODE = 901
    MONTH_NAMES = %w[
      января февраля марта апреля мая июня июля августа сентября октября ноября декабря
    ].freeze
    TYPE_ICONS = {
      "medication" => "💊",
      "vaccination" => "💉",
      "treatment" => "🩹",
      "visit" => "🩺",
      "weight" => "⚖️",
      "other" => "🐾"
    }.freeze

    def deliver(delivery, test_delivery: false)
      token = VkConfiguration.group_token
      raise "VK-уведомления временно недоступны. Попробуйте позже." if token.blank?

      reminder = delivery.reminder
      params = {
        access_token: token,
        peer_id: channel.address,
        random_id: SecureRandom.random_number(2_147_483_647),
        message: test_delivery ? test_message : reminder_message(reminder),
        v: VkConfiguration.api_version
      }

      keyboard = reminder_keyboard(reminder) unless test_delivery
      params[:keyboard] = keyboard if keyboard.present?

      response = Net::HTTP.post_form(URI(VK_ENDPOINT), params)
      body = JSON.parse(response.body)
      handle_vk_error!(body["error"]) if body["error"].present?
    end

    private

    def test_message
      [
        "✅ VK подключён",
        "",
        "Тестовое уведомление PetJournal успешно доставлено.",
        "",
        "Теперь сюда будут приходить напоминания о важных событиях вашего питомца. 🐾"
      ].join("\n")
    end

    def reminder_message(reminder)
      lines = [
        "🐾 PetJournal",
        "",
        "Пора: #{reminder.title}",
        "для #{reminder.pet.name}",
        "",
        "🕒 #{friendly_time(reminder)}",
        "#{TYPE_ICONS.fetch(reminder.reminder_type, "🐾")} #{reminder.reminder_type_label}"
      ]

      if reminder.note.present?
        lines << ""
        lines << "📝 #{reminder.note}"
      end

      lines.join("\n")
    end

    def friendly_time(reminder)
      zone_name = reminder.user.notifications_time_zone_name
      time = reminder.next_run_at.in_time_zone(zone_name)
      now = Time.current.in_time_zone(zone_name)

      day_label = case time.to_date
      when now.to_date
        "Сегодня"
      when now.to_date + 1.day
        "Завтра"
      else
        label = "#{time.day} #{MONTH_NAMES.fetch(time.month - 1)}"
        label += " #{time.year}" if time.year != now.year
        label
      end

      "#{day_label}, #{time.strftime('%H:%M')}"
    end

    def reminder_keyboard(reminder)
      url = reminder_url(reminder)
      return if url.blank?

      {
        inline: true,
        buttons: [
          [
            {
              action: {
                type: "open_link",
                link: url,
                label: "Открыть напоминание"
              }
            }
          ]
        ]
      }.to_json
    end

    def reminder_url(reminder)
      defaults = Rails.application.config.action_mailer.default_url_options.to_h.symbolize_keys
      return if defaults[:host].blank?

      Rails.application.routes.url_helpers.pet_reminder_url(
        reminder.pet,
        reminder,
        **defaults
      )
    rescue ArgumentError
      nil
    end

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
    def deliver(delivery, test_delivery: false)
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
