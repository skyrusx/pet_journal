class PetEvent < ApplicationRecord
  belongs_to :pet

  has_many_attached :files

  validates :event_type, :event_date, presence: true
end
