class PetTag < ApplicationRecord
  belongs_to :pet

  has_secure_token :public_token

  validates :public_token, presence: true, uniqueness: true
  validates :pet_id, uniqueness: true

  def public_path
    "/p/#{public_token}"
  end
end
