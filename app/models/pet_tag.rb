class PetTag < ApplicationRecord
  belongs_to :pet
  has_many :pet_tag_scans, dependent: :destroy
  has_many :pet_tag_notification_channels, dependent: :destroy
  has_many :notification_channels, through: :pet_tag_notification_channels

  has_secure_token :public_token

  enum :notification_preference, { never: 0, lost_mode: 1, always: 2 }, prefix: :notify
  enum :safety_status, { safe: 0, lost: 1, found: 2, reunited: 3 }, prefix: :status

  validates :public_token, presence: true, uniqueness: true
  validates :pet_id, uniqueness: true
  validates :public_message, length: { maximum: 500 }
  validates :behavior_notes, :medical_notes, :lost_message, :found_message, length: { maximum: 1_000 }
  validates :contact_phone, length: { maximum: 40 }
  validates :last_seen_location, length: { maximum: 255 }
  before_validation :sync_legacy_lost_mode

  def public_path
    "/p/#{public_token}"
  end

  def notify_on_scan?
    notify_always? || (notify_lost_mode? && lost_mode_enabled?)
  end

  def lost_mode_enabled?
    status_lost? || self[:lost_mode_enabled]
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

  private

  def sync_legacy_lost_mode
    self.safety_status = :lost if self[:lost_mode_enabled] && status_safe?
    self.lost_mode_enabled = status_lost? || status_found?
  end
end
