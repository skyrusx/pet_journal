class BirthdayGreetingMailer < ApplicationMailer
  LOGO_PATH = Rails.root.join("app/assets/images/petjournal/logo-horizontal.png").freeze

  def greeting(user, pets, greeting_date)
    @user = user
    @presenter = BirthdayGreetingPresenter.new(pets: pets, date: greeting_date)

    attachments.inline["petjournal-logo.png"] = File.binread(LOGO_PATH) if LOGO_PATH.file?

    mail(
      to: user.email,
      subject: "#{@presenter.title.delete_prefix('🎉 ')} — PetJournal"
    )
  end
end
