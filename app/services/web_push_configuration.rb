class WebPushConfiguration
  DEFAULT_SUBJECT = "mailto:support@pet-journal.ru".freeze

  class << self
    def public_key
      ENV["VAPID_PUBLIC_KEY"].presence || credential(:public_key)
    end

    def private_key
      ENV["VAPID_PRIVATE_KEY"].presence || credential(:private_key)
    end

    def subject
      ENV["VAPID_SUBJECT"].presence || credential(:subject).presence || DEFAULT_SUBJECT
    end

    def configured?
      public_key.present? && private_key.present?
    end

    def vapid_options
      raise "VAPID-ключи Web Push не настроены" unless configured?

      {
        subject: subject,
        public_key: public_key,
        private_key: private_key
      }
    end

    private

    def credential(key)
      Rails.application.credentials.dig(:web_push, key) ||
        Rails.application.credentials.dig(:vapid, key)
    end
  end
end
