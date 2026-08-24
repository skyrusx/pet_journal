class TelegramConfiguration
  class << self
    def bot_token
      ENV["TELEGRAM_BOT_TOKEN"].presence || credential(:bot_token)
    end

    def bot_username
      value = ENV["TELEGRAM_BOT_USERNAME"].presence || credential(:bot_username)
      value.to_s.delete_prefix("@").presence
    end

    def configured?
      bot_token.present? && bot_username.present?
    end

    private

    def credential(key)
      Rails.application.credentials.dig(:telegram, key)
    end
  end
end
