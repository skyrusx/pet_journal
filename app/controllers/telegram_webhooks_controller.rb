class TelegramWebhooksController < ApplicationController
  skip_forgery_protection

  before_action :verify_webhook_secret

  def create
    message = params[:message]
    return head :ok if message.blank?

    text = message[:text].to_s
    chat_id = message.dig(:chat, :id)
    return head :ok if chat_id.blank?

    if (match = text.match(%r{\A/start(?:@\w+)?(?:\s+(\S+))?\z}))
      connect_account(chat_id, message[:from] || {}, match[1])
    end

    head :ok
  end

  private

  def verify_webhook_secret
    expected = ENV["TELEGRAM_WEBHOOK_SECRET"].to_s

    if expected.blank?
      return unless Rails.env.production?

      head :unauthorized
      return
    end

    actual = request.headers["X-Telegram-Bot-Api-Secret-Token"].to_s
    valid = actual.bytesize == expected.bytesize && ActiveSupport::SecurityUtils.secure_compare(actual, expected)
    head :unauthorized unless valid
  end

  def connect_account(chat_id, telegram_user, token)
    user = TelegramConnectionToken.resolve(token)

    username = telegram_user[:username].to_s.presence
    display_name = [telegram_user[:first_name], telegram_user[:last_name]].compact.join(" ").presence

    channel = user.notification_channels.find_or_initialize_by(channel_type: :telegram, address: chat_id.to_s)
    channel.name = "Telegram" if channel.name.blank?
    channel.enabled = true if channel.new_record?
    channel.verified_at = Time.current
    channel.settings = channel.settings.merge(
      "username" => username,
      "display_name" => display_name,
      "telegram_user_id" => telegram_user[:id].to_s.presence
    ).compact
    channel.save!

    account_label = username.present? ? "@#{username}" : display_name
    text = [
      "Готово! Telegram подключён к PetJournal.",
      account_label.present? ? "Аккаунт: #{account_label}" : nil,
      "Теперь сюда можно получать напоминания о питомцах."
    ].compact.join("\n")

    NotificationChannelConnectors::TelegramBot.send_message(chat_id: chat_id, text: text)
  rescue TelegramConnectionToken::InvalidToken
    NotificationChannelConnectors::TelegramBot.send_message(
      chat_id: chat_id,
      text: "Ссылка подключения устарела. Вернитесь в PetJournal и нажмите «Подключить Telegram» ещё раз."
    )
  rescue StandardError => e
    Rails.logger.error("Telegram account linking failed: #{e.class}: #{e.message}")

    NotificationChannelConnectors::TelegramBot.send_message(
      chat_id: chat_id,
      text: "Не удалось подключить Telegram. Попробуйте ещё раз из настроек PetJournal."
    )
  rescue NotificationChannelConnectors::TelegramBot::Error => e
    Rails.logger.error("Telegram confirmation failed: #{e.message}")
  end
end
