class PetProfileShare < ApplicationRecord
  belongs_to :pet
  has_many :pet_profile_share_views, dependent: :destroy

  has_secure_token :public_token

  enum :detail_level, {
    brief: 0,
    full: 1
  }, prefix: :detail

  validates :title, presence: true
  validates :public_token, presence: true, uniqueness: true
  validate :at_least_one_section_enabled

  scope :enabled, -> { where(enabled: true) }
  scope :active, -> { enabled.where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :recent, -> { order(created_at: :desc) }

  SECTIONS = %i[profile journal documents reminders pet_tag].freeze

  def active?
    enabled? && !expired?
  end

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  def section_enabled?(section)
    public_send("show_#{section}?")
  end

  def views_count
    pet_profile_share_views.size
  end

  private

  def at_least_one_section_enabled
    return if SECTIONS.any? { |section| public_send("show_#{section}?") }

    errors.add(:base, "выберите хотя бы один раздел профиля")
  end
end
