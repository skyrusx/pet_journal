class VkConfiguration
  DEFAULT_API_VERSION = "5.199".freeze

  class << self
    def group_token
      credential(:group_token).presence || ENV["VK_GROUP_TOKEN"].presence
    end

    def api_version
      credential(:api_version).presence || ENV["VK_API_VERSION"].presence || DEFAULT_API_VERSION
    end

    def configured?
      group_token.present?
    end

    private

    def credential(key)
      Rails.application.credentials.dig(:vk, key)
    end
  end
end
