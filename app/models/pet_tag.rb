class PetTag < ApplicationRecord
  TAG_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".freeze
  PHONE_DISTRIBUTION_PURPOSE = "Связь с владельцем питомца после открытия публичной страницы PetTag".freeze
  PHONE_DISTRIBUTION_CONDITIONS = "Только предоставление доступа к номеру через публичную страницу PetTag; дальнейшая передача оператором не допускается.".freeze

  belongs_to :pet
  has_many :pet_tag_scans, dependent: :destroy
  has_many :pet_tag_notification_channels, dependent: :destroy
  has_many :notification_channels, through: :pet_tag_notification_channels
  has_many :user_consents, as: :consentable

  has_secure_token :public_token

  enum :notification_preference, { never: 0, lost_mode: 1, always: 2 }, prefix: :notify
  enum :safety_status, { safe: 0, lost: 1, found: 2, reunited: 3 }, prefix: :status

  validates :public_token, presence: true, uniqueness: true
  validates :tag_code, presence: true, uniqueness: true, format: { with: /\APJT-[A-Z2-9]{4}-[A-Z2-9]{4}\z/ }
  validates :pet_id, uniqueness: true
  validates :public_message, length: { maximum: 500 }
  validates :behavior_notes, :medical_notes, :lost_message, :found_message, length: { maximum: 1_000 }
  validates :contact_phone, length: { maximum: 40 }
  validates :last_seen_location, length: { maximum: 255 }

  before_validation :ensure_tag_code, on: :create
  before_validation :sync_legacy_lost_mode
  before_update :revoke_phone_distribution_consent_if_phone_changed

  def public_path
    "/p/#{public_token}"
  end

  def notify_on_scan?
    notify_always? || (notify_lost_mode? && lost_mode_enabled?)
  end

  def lost_mode_enabled?
    status_lost? || self[:lost_mode_enabled]
  end

  def active_phone_distribution_consent
    user_consents.active
                 .where(consent_type: UserConsent::PET_TAG_PHONE_DISTRIBUTION)
                 .order(accepted_at: :desc)
                 .first
  end

  def phone_publication_allowed?(public_url: nil)
    return false unless show_phone? && contact_phone.present?

    consent = active_phone_distribution_consent
    return false unless consent.present?
    return false unless consent.metadata["phone"].to_s == contact_phone.to_s
    return false unless consent.metadata["public_token"].to_s == public_token.to_s
    return false if public_url.present? && consent.metadata["public_resource_url"].to_s != public_url.to_s

    true
  end

  def public_phone(public_url: nil)
    contact_phone if phone_publication_allowed?(public_url: public_url)
  end

  def publish_phone!(user:, subject_full_name:, subject_contact:, ip_address:, user_agent:, public_url:)
    unless contact_phone.present?
      errors.add(:contact_phone, "нужно указать перед публикацией")
      raise ActiveRecord::RecordInvalid, self
    end

    unless user == pet.user
      errors.add(:base, "согласие может дать только владелец PetTag")
      raise ActiveRecord::RecordInvalid, self
    end

    transaction do
      consent = user.user_consents.create!(
        consentable: self,
        consent_type: UserConsent::PET_TAG_PHONE_DISTRIBUTION,
        document_version: LegalDocuments.version(:pet_tag_phone_distribution_consent),
        accepted_at: Time.current,
        source: "pet_tag_settings",
        ip_address: ip_address,
        user_agent: user_agent.to_s.truncate(500),
        metadata: {
          "privacy_policy_version" => LegalDocuments.version(:privacy_policy),
          "subject_full_name" => subject_full_name,
          "subject_contact" => subject_contact,
          "phone" => contact_phone,
          "pet_tag_id" => id,
          "pet_tag_code" => tag_code,
          "public_token" => public_token,
          "public_resource_url" => public_url,
          "purpose" => PHONE_DISTRIBUTION_PURPOSE,
          "conditions" => PHONE_DISTRIBUTION_CONDITIONS,
          "operator_name" => LegalOperatorConfiguration.name,
          "operator_details" => LegalOperatorConfiguration.details,
          "operator_email" => LegalOperatorConfiguration.email
        }
      )

      update!(show_phone: true)
      consent
    end
  end

  def revoke_phone_publication!
    now = Time.current

    transaction do
      user_consents.active
                   .where(consent_type: UserConsent::PET_TAG_PHONE_DISTRIBUTION)
                   .find_each { |consent| consent.update!(revoked_at: now) }
      update!(show_phone: false) if show_phone?
    end
  end

  def mark_lost!
    update!(safety_status: :lost, lost_mode_enabled: true, reunited_at: nil)
  end

  def mark_found!(message: nil)
    update!(safety_status: :found, lost_mode_enabled: true, found_message: message.presence || found_message)
  end

  def mark_reunited!
    update!(safety_status: :reunited, lost_mode_enabled: false, reunited_at: Time.current)
  end

  def mark_safe!
    update!(safety_status: :safe, lost_mode_enabled: false)
  end

  private

  def ensure_tag_code
    return if tag_code.present?

    loop do
      raw = Array.new(8) { TAG_CODE_ALPHABET[SecureRandom.random_number(TAG_CODE_ALPHABET.length)] }.join
      self.tag_code = "PJT-#{raw.first(4)}-#{raw.last(4)}"
      break unless self.class.exists?(tag_code: tag_code)
    end
  end

  def sync_legacy_lost_mode
    self.safety_status = :lost if self[:lost_mode_enabled] && status_safe?
    self.lost_mode_enabled = status_lost? || status_found?
  end

  def revoke_phone_distribution_consent_if_phone_changed
    return unless will_save_change_to_contact_phone?

    self.show_phone = false
    now = Time.current
    user_consents.active
                 .where(consent_type: UserConsent::PET_TAG_PHONE_DISTRIBUTION)
                 .update_all(revoked_at: now, updated_at: now)
  end
end
