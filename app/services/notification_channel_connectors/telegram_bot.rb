require "json"
require "net/http"

module NotificationChannelConnectors
  class TelegramBot
    API_ROOT = "https://api.telegram.org/bot".freeze

    class Error < StandardError; end

    def self.send_message(chat_id:, text:)
      post("sendMessage", chat_id: chat_id, text: text)
    end

    def self.set_webhook(url:, secret_token:)
      post("setWebhook", url: url, secret_token: secret_token, allowed_updates: ["message"])
    end

    def self.post(method, payload)
      token = TelegramConfiguration.bot_token
      raise Error, "Telegram пока в разработке и недоступен для подключения." if token.blank?

      uri = URI("#{API_ROOT}#{token}/#{method}")
      response = Net::HTTP.post(uri, payload.to_json, "Content-Type" => "application/json")
      body = JSON.parse(response.body)

      raise Error, body.dig("description") || "Telegram API вернул ошибку" unless response.is_a?(Net::HTTPSuccess) && body["ok"]

      body["result"]
    rescue JSON::ParserError
      raise Error, "Telegram API вернул некорректный ответ"
    end
    private_class_method :post
  end
end
