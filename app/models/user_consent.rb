class UserConsent < ApplicationRecord
  PERSONAL_DATA = "personal_data".freeze
  CONSENT_TYPES = [PERSONAL_DATA].freeze
  SOURCES = %w[registration].freeze

  belongs_to :user

  scope :active, -> { where(revoked_at: nil) }

  validates :consent_type, presence: true, inclusion: { in: CONSENT_TYPES }
  validates :document_version, presence: true, length: { maximum: 32 }
  validates :accepted_at, presence: true
  validates :source, presence: true, inclusion: { in: SOURCES }
  validates :user_agent, length: { maximum: 500 }, allow_blank: true
  validates :consent_type,
            uniqueness: {
              scope: %i[user_id document_version],
              conditions: -> { where(revoked_at: nil) }
            },
            if: -> { revoked_at.nil? }
  validate :revocation_not_before_acceptance

  def active?
    revoked_at.nil?
  end

  private

  def revocation_not_before_acceptance
    return if revoked_at.blank? || accepted_at.blank? || revoked_at >= accepted_at

    errors.add(:revoked_at, "не может быть раньше даты принятия согласия")
  end
end
