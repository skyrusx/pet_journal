class LegalOperatorConfiguration
  DEFAULT_EMAIL = "support@pet-journal.ru".freeze
  REQUIRED_ENV = %w[
    LEGAL_OPERATOR_NAME
    LEGAL_OPERATOR_EMAIL
  ].freeze

  class << self
    def name(env = ENV)
      env["LEGAL_OPERATOR_NAME"].presence || "Оператор сервиса PetJournal"
    end

    def email(env = ENV)
      env["LEGAL_OPERATOR_EMAIL"].presence || DEFAULT_EMAIL
    end

    def details(env = ENV)
      env["LEGAL_OPERATOR_DETAILS"].presence
    end

    def missing_required_env(env = ENV)
      REQUIRED_ENV.reject { |key| env[key].present? }
    end
  end
end
