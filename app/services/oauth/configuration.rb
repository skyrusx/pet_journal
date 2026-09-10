module Oauth
  class Configuration
    PROVIDERS = ExternalIdentity::PROVIDERS.freeze

    class << self
      def configured?(provider)
        provider = provider.to_s
        return false unless PROVIDERS.include?(provider)

        client_id(provider).present? && (provider != "yandex" || client_secret(provider).present?)
      end

      def client_id(provider)
        value(provider, :client_id)
      end

      def client_secret(provider)
        value(provider, :client_secret)
      end

      def provider_name(provider)
        case provider.to_s
        when "vk" then "VK ID"
        when "yandex" then "Яндекс ID"
        else provider.to_s.humanize
        end
      end

      private

      def value(provider, key)
        provider = provider.to_s
        env_name = "#{provider.upcase}_#{key.to_s.upcase}"
        ENV[env_name].presence || Rails.application.credentials.dig(:oauth, provider.to_sym, key)
      end
    end
  end
end
