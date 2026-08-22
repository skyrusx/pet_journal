require "json"
require "net/http"

module NotificationChannelConnectors
  class VkProfileResolver
    ENDPOINT = "https://api.vk.com/method/users.get".freeze

    Result = Data.define(:user_id, :screen_name, :display_name)
    class Error < StandardError; end

    def self.call(value)
      identifier = normalize(value)
      raise Error, "Укажите ссылку на профиль VK, короткое имя или ID." if identifier.blank?

      token = ENV["VK_GROUP_TOKEN"].presence
      raise Error, "Подключение VK пока недоступно. Попробуйте позже." if token.blank?

      response = Net::HTTP.post_form(URI(ENDPOINT), {
        access_token: token,
        user_ids: identifier,
        fields: "screen_name",
        v: ENV.fetch("VK_API_VERSION", "5.199")
      })
      body = JSON.parse(response.body)

      if body["error"].present?
        Rails.logger.warn("VK profile resolve failed: #{body.dig("error", "error_msg")}")
        raise Error, "Не удалось найти этот профиль VK. Проверьте ссылку или короткое имя."
      end

      user = Array(body["response"]).first
      raise Error, "Не удалось найти этот профиль VK. Проверьте ссылку или короткое имя." if user.blank?

      Result.new(
        user_id: user.fetch("id").to_s,
        screen_name: user["screen_name"].presence || screen_name_from(identifier, user.fetch("id")),
        display_name: [user["first_name"], user["last_name"]].compact.join(" ").presence
      )
    rescue JSON::ParserError, KeyError => e
      Rails.logger.warn("VK profile resolve response error: #{e.message}")
      raise Error, "VK временно недоступен. Попробуйте позже."
    end

    def self.normalize(value)
      value = value.to_s.strip
      return if value.blank?

      value = value.sub(%r{\Ahttps?://}i, "")
      value = value.sub(%r{\A(?:www\.)?(?:vk\.ru|vk\.com)/}i, "")
      value = value.split(/[?#]/, 2).first.to_s
      value = value.split("/", 2).first.to_s
      value = value.delete_prefix("@")
      value = value.delete_prefix("id") if value.match?(/\Aid\d+\z/i)
      value.presence
    end

    def self.screen_name_from(identifier, user_id)
      identifier.match?(/\A\d+\z/) ? "id#{user_id}" : identifier
    end
    private_class_method :screen_name_from
  end
end
