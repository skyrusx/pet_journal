class Pet < ApplicationRecord
  belongs_to :user
  has_many :pet_events, dependent: :destroy
  has_many :reminders, dependent: :destroy
  has_many :pet_documents, dependent: :destroy
  has_one :pet_tag, dependent: :destroy

  has_one_attached :photo

  validates :name, presence: true
end
