class PetTagScan < ApplicationRecord
  belongs_to :pet_tag

  has_secure_token :public_token
  enum :scan_status, { scanned: 0, location_shared: 1, found_reported: 2 }, prefix: :status

  validates :public_token, presence: true, uniqueness: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_blank: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_blank: true
  validates :location_note, :finder_name, length: { maximum: 120 }
  validates :finder_contact, length: { maximum: 160 }
  validates :finder_message, length: { maximum: 1_000 }

  def location_shared?
    location_shared_at.present? || status_location_shared? || status_found_reported?
  end

  def location_label
    return location_note if location_note.present?
    return unless latitude.present? && longitude.present?

    "#{latitude}, #{longitude}"
  end

  def finder_contact_present?
    finder_name.present? || finder_contact.present? || finder_message.present?
  end
end
