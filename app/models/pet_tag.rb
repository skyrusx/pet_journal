class PetTag < ApplicationRecord
  belongs_to :pet
  has_many :pet_tag_scans, dependent: :destroy

  has_secure_token :public_token

  enum :notification_preference, { never: 0, lost_mode: 1, always: 2 }, prefix: :notify

  validates :public_token, presence: true, uniqueness: true
  validates :pet_id, uniqueness: true

  def public_path
    "/p/#{public_token}"
  end

  def notify_on_scan?
    notify_always? || (notify_lost_mode? && lost_mode_enabled?)
  end
end
