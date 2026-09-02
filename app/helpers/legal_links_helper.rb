module LegalLinksHelper
  LEGAL_LINKS = {
    privacy: {
      label: "Политика конфиденциальности",
      path_helper: :privacy_path
    },
    personal_data_consent: {
      label: "Согласие на обработку персональных данных",
      path_helper: :personal_data_consent_path
    },
    pet_tag_data_consent: {
      label: "Согласие на обработку данных отправителя PetTag",
      path_helper: :pet_tag_data_consent_path
    },
    pet_tag_phone_distribution_consent: {
      label: "Согласие на публикацию телефона в PetTag",
      path_helper: :pet_tag_phone_distribution_consent_path
    }
  }.freeze

  def legal_link_label(document, lowercase: false)
    label = LEGAL_LINKS.fetch(document).fetch(:label)
    lowercase ? label.sub(/\A./) { |char| char.downcase } : label
  end

  def legal_link(document, lowercase: false, **options)
    config = LEGAL_LINKS.fetch(document)
    options[:class] = class_names("pj-legal-link", options[:class])

    link_to(
      legal_link_label(document, lowercase: lowercase),
      public_send(config.fetch(:path_helper)),
      **options
    )
  end
end
