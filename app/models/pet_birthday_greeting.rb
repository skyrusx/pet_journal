class PetBirthdayGreeting < ApplicationRecord
  belongs_to :user

  validates :greeting_date, presence: true

  def claim_for_display!
    with_lock do
      return false if shown_at.present?

      update!(shown_at: Time.current)
    end

    true
  end
end
