class LegalDocuments
  DOCUMENTS = {
    privacy_policy: {
      version: "1.0",
      effective_on: Date.new(2026, 8, 27),
      title: "Политика в отношении обработки персональных данных"
    },
    personal_data_consent: {
      version: "1.0",
      effective_on: Date.new(2026, 8, 27),
      title: "Согласие на обработку персональных данных"
    },
    pet_tag_finder_consent: {
      version: "1.0",
      effective_on: Date.new(2026, 8, 27),
      title: "Согласие на обработку данных отправителя PetTag"
    }
  }.freeze

  class << self
    def fetch(key)
      DOCUMENTS.fetch(key)
    end

    def version(key)
      fetch(key).fetch(:version)
    end
  end
end
