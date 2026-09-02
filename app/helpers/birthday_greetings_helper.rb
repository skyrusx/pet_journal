module BirthdayGreetingsHelper
  def birthday_greeting_presenter
    return @birthday_greeting_presenter if defined?(@birthday_greeting_presenter)

    @birthday_greeting_presenter = nil
    return unless user_signed_in?

    date = Date.current
    pets = current_user.pets
                       .with_attached_photo
                       .birthday_on(date)
                       .order(:created_at)
                       .to_a
    return if pets.empty?

    greeting = PetBirthdayGreeting.create_or_find_by!(user: current_user, greeting_date: date)
    return unless greeting.claim_for_display!

    @birthday_greeting_presenter = BirthdayGreetingPresenter.new(pets: pets, date: date)
  end
end
