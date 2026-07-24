class PetProfileShareView < ApplicationRecord
  belongs_to :pet_profile_share

  validates :public_token, presence: true
end
