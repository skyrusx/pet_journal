require "ipaddr"
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
      return if url.blank? || !public_http_url?(url)

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

    # VK validates open_link keyboard URLs. Development addresses such as
    # localhost, *.local or private LAN IPs are not reachable from VK and can
    # make the whole messages.send request fail. The reminder itself must still
    # be delivered, so the button is attached only for a public web address.
    def public_http_url?(url)
      uri = URI.parse(url)
      return false unless %w[http https].include?(uri.scheme)

      host = uri.host.to_s.downcase
      return false if host.blank?
      return false if host == "localhost" || host.end_with?(".localhost", ".local", ".test")

      ip = IPAddr.new(host)
      return false if ip.loopback? || ip.private? || ip.link_local?

      true
    rescue IPAddr::InvalidAddressError
      true
    rescue URI::InvalidURIError
      false
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
        "ВКонтакте не смог отправить уведомление. Переподключите канал и повторите попытку."
      else
        "ВКонтакте не смог отправить уведомление. Проверьте подключение канала и повторите попытку."
      end

      raise message
    end
  end

  class WebPush < Base
    def deliver(delivery, test_delivery: false)
      require "webpush"

      reminder = delivery.reminder
      payload = test_delivery ? test_payload : reminder_payload(reminder)

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

    def test_payload
      {
        title: "✅ Push подключён",
        body: "Тестовое уведомление PetJournal успешно доставлено.",
        path: Rails.application.routes.url_helpers.notification_channels_path,
        tag: "petjournal-push-test",
        timestamp: Time.current.to_i * 1000,
        require_interaction: true
      }
    end

    def reminder_payload(reminder)
      {
        title: "⏰ #{reminder.title}",
        body: reminder_body(reminder),
        path: Rails.application.routes.url_helpers.pet_reminder_path(reminder.pet, reminder),
        tag: "reminder-#{reminder.id}",
        timestamp: reminder.next_run_at.to_i * 1000,
        require_interaction: true
      }
    end

    def reminder_body(reminder)
      lines = [
        "#{reminder.pet.name} • #{friendly_time(reminder)} • #{reminder.reminder_type_label}"
      ]
      lines << reminder.note if reminder.note.present?
      lines.join("\n")
    end

    def friendly_time(reminder)
      zone_name = reminder.user.notifications_time_zone_name
      time = reminder.next_run_at.in_time_zone(zone_name)
      now = Time.current.in_time_zone(zone_name)

      if time.to_date == now.to_date
        "Сегодня, #{time.strftime('%H:%M')}"
      else
        time.strftime("%d.%m.%Y, %H:%M")
      end
    end

    def invalidate_subscription!
      channel.update!(
        enabled: false,
        verified_at: nil,
        settings: channel.settings.merge("invalidated_at" => Time.current.iso8601)
      )
    end
  end
end
