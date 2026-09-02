class Pet < ApplicationRecord
  belongs_to :user
  has_many :pet_events, dependent: :destroy
  has_many :reminders, dependent: :destroy
  has_many :pet_documents, dependent: :destroy
  has_many :pet_profile_shares, dependent: :destroy
  has_one :pet_tag, dependent: :destroy

  has_one_attached :photo

  validates :name, presence: true

  scope :birthday_on, lambda { |date|
    where.not(birth_date: nil)
         .where("EXTRACT(MONTH FROM birth_date) = ?", date.month)
         .where("EXTRACT(DAY FROM birth_date) = ?", date.day)
  }

  def birthday_on?(date)
    birth_date.present? && birth_date.month == date.month && birth_date.day == date.day
  end

  def age_on(date)
    return if birth_date.blank?

    years = date.year - birth_date.year
    birthday_has_not_happened = date.month < birth_date.month ||
                                (date.month == birth_date.month && date.day < birth_date.day)
    years -= 1 if birthday_has_not_happened
    [years, 0].max
  end
end
