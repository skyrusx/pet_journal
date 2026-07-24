web: bundle exec rails server -p ${PORT:-3000}
worker: bundle exec rails reminders:dispatch_loop
release: bundle exec rails db:migrate release:check
