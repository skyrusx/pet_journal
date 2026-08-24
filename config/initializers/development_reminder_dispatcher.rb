# In development PetJournal is usually started with only `bin/rails server`.
# Run the reminder dispatcher alongside the web server so scheduled notifications
# can be tested at their real time without a second terminal. Production keeps
# using the dedicated worker/cron process from Procfile.
if Rails.env.development? && defined?(Rails::Server)
  Rails.application.config.after_initialize do
    interval = ENV.fetch("REMINDER_DISPATCH_INTERVAL", "10").to_i.clamp(10, 3600)

    Thread.new do
      Thread.current.name = "petjournal-reminder-dispatcher" if Thread.current.respond_to?(:name=)

      loop do
        Rails.application.executor.wrap do
          NotificationDispatcher.dispatch_all
        rescue StandardError => error
          Rails.logger.error("development reminder dispatcher failed: #{error.class}: #{error.message}")
        end

        sleep interval
      end
    end
  end
end
