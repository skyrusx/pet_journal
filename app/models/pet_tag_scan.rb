class PetTagScan < ApplicationRecord
  belongs_to :pet_tag

  has_secure_token :public_token

  validates :public_token, presence: true, uniqueness: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_blank: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_blank: true

  def location_shared?
    location_shared_at.present?
  end

  def location_label
    return location_note if location_note.present?
    return unless latitude.present? && longitude.present?

    "#{latitude}, #{longitude}"
  end
end
