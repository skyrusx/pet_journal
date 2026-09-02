class PetBirthdayGreeting < ApplicationRecord
  belongs_to :user

  validates :greeting_date, presence: true
  validates :greeting_date, uniqueness: { scope: :user_id }

  def claim_for_display!
    with_lock do
      return false if shown_at.present?

      update!(shown_at: Time.current)
    end

    true
  end
end
