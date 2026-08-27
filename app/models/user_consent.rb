class UserConsent < ApplicationRecord
  PERSONAL_DATA = "personal_data".freeze
  PET_TAG_PHONE_DISTRIBUTION = "pet_tag_phone_distribution".freeze
  DISTRIBUTION_METADATA_KEYS = %w[
    subject_full_name
    subject_contact
    phone
    pet_tag_id
    pet_tag_code
    public_token
    public_resource_url
    purpose
    conditions
    operator_name
    operator_email
  ].freeze

  CONSENT_TYPES = [PERSONAL_DATA, PET_TAG_PHONE_DISTRIBUTION].freeze
  SOURCES = %w[registration pet_tag_settings].freeze

  belongs_to :user
  belongs_to :consentable, polymorphic: true, optional: true

  scope :active, -> { where(revoked_at: nil) }

  validates :consent_type, presence: true, inclusion: { in: CONSENT_TYPES }
  validates :document_version, presence: true, length: { maximum: 32 }
  validates :accepted_at, presence: true
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :user_agent, length: { maximum: 500 }, allow_blank: true
  validate :consent_scope_matches_type
  validate :distribution_metadata_is_complete, if: -> { consent_type == PET_TAG_PHONE_DISTRIBUTION }
  validate :active_consent_is_unique, if: -> { revoked_at.nil? }
  validate :revocation_not_before_acceptance

  def active?
    revoked_at.nil?
  end

  private

  def consent_scope_matches_type
    if consent_type == PET_TAG_PHONE_DISTRIBUTION
      errors.add(:consentable, "должен быть PetTag") unless consentable.is_a?(PetTag)
      errors.add(:source, "должен быть pet_tag_settings") unless source == "pet_tag_settings"
    elsif consentable.present? || consentable_type.present? || consentable_id.present?
      errors.add(:consentable, "не должен быть указан для этого типа согласия")
    end
  end

  def distribution_metadata_is_complete
    missing = DISTRIBUTION_METADATA_KEYS.reject { |key| metadata.to_h[key].present? }
    errors.add(:metadata, "не содержит обязательные сведения: #{missing.join(", ")}") if missing.any?
  end

  def active_consent_is_unique
    return if user_id.blank? || consent_type.blank?

    relation = self.class.active.where(user_id: user_id, consent_type: consent_type)
    relation = relation.where.not(id: id) if persisted?

    relation = if consent_type == PET_TAG_PHONE_DISTRIBUTION
                 relation.where(consentable_type: consentable_type, consentable_id: consentable_id)
               else
                 relation.where(document_version: document_version, consentable_type: nil, consentable_id: nil)
               end

    errors.add(:consent_type, "уже имеет действующее согласие") if relation.exists?
  end

  def revocation_not_before_acceptance
    return if revoked_at.blank? || accepted_at.blank? || revoked_at >= accepted_at

    errors.add(:revoked_at, "не может быть раньше даты принятия согласия")
  end
end
