class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "PetJournal <no-reply@petjournal.local>") }
  layout "mailer"
end
