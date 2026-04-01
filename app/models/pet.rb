class Pet < ApplicationRecord
  belongs_to :user
  has_many :pet_events, dependent: :destroy

  has_one_attached :photo

  validates :name, presence: true
end
