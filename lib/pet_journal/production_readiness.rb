module PetJournal
  class ProductionReadiness
    CORE_ENV = %w[
      APP_HOST
      SECRET_KEY_BASE
    ].freeze

    DATABASE_ENV = %w[
      DATABASE_URL
      PET_JOURNAL_DATABASE_PASSWORD
    ].freeze

    LEGAL_ENV = %w[
      LEGAL_OPERATOR_NAME
      LEGAL_OPERATOR_EMAIL
    ].freeze

    MAIL_ENV = %w[
      MAIL_FROM
      SMTP_ADDRESS
      SMTP_DOMAIN
      SMTP_USER_NAME
      SMTP_PASSWORD
    ].freeze

    PUSH_ENV = %w[
      VAPID_PUBLIC_KEY
      VAPID_PRIVATE_KEY
    ].freeze

    class << self
      def missing_required_env(env = ENV)
        missing = CORE_ENV.reject { |key| env[key].present? }
        missing << DATABASE_ENV.join(" or ") unless DATABASE_ENV.any? { |key| env[key].present? }
        missing.concat(LEGAL_ENV.reject { |key| env[key].present? })
        missing
      end

      def notification_warnings(env = ENV)
        warnings = []
        warnings << "Email delivery is not configured: #{missing_mail_env(env).join(', ')}" if missing_mail_env(env).any?
        warnings << "Web Push is not configured: add VAPID_PUBLIC_KEY/VAPID_PRIVATE_KEY or web_push Rails credentials" unless push_configured?(env)
        warnings << "Telegram delivery is unavailable without TELEGRAM_BOT_TOKEN" if env["TELEGRAM_BOT_TOKEN"].blank?
        warnings << "VK delivery is unavailable: add VK_GROUP_TOKEN or vk.group_token Rails credentials" unless vk_configured?(env)
        warnings
      end

      def report(env = ENV)
        {
          missing_required_env: missing_required_env(env),
          notification_warnings: notification_warnings(env)
        }
      end

      private

      def missing_mail_env(env)
        MAIL_ENV.reject { |key| env[key].present? }
      end

      def push_configured?(env)
        return true if PUSH_ENV.all? { |key| env[key].present? }

        env.equal?(ENV) && WebPushConfiguration.configured?
      end

      def vk_configured?(env)
        return true if env["VK_GROUP_TOKEN"].present?

        env.equal?(ENV) && VkConfiguration.configured?
      end
    end
  end
end
