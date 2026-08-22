# Release Checklist

## Required Checks

- `bin/rails test`
- `bin/rails test test/integration/pre_release_scenarios_test.rb`
- `bin/rubocop`
- `bin/brakeman --no-pager`
- `bin/importmap audit`
- `bin/rails release:check`

## Runtime

- Upgrade Ruby from `3.2.2` to a supported release before production release.
- Upgrade Rails from `7.2.3.1` before its support window ends.

## Environment

- Set `APP_HOST`.
- Set `SECRET_KEY_BASE`.
- Set `DATABASE_URL` or `PET_JOURNAL_DATABASE_PASSWORD`.
- Set `MAIL_FROM`.
- Configure SMTP for email reminders.
- Set `TELEGRAM_BOT_TOKEN`, `TELEGRAM_BOT_USERNAME`, and `TELEGRAM_WEBHOOK_SECRET` if Telegram delivery is enabled.
- Optionally set a separate `TELEGRAM_CONNECTION_SECRET`; otherwise `SECRET_KEY_BASE` is used for account-link tokens.
- Run `bundle exec rails notifications:setup_telegram_webhook` after Telegram bot configuration or host changes.
- Set `VK_GROUP_TOKEN` and `VK_API_VERSION` if VK delivery is enabled.
- Verify the PetJournal VK community allows users to start a dialog and receive messages.
- Set `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT` for browser push.
- Run `bin/rails reminders:dispatch_loop` as a worker process, or run `bin/rails reminders:dispatch` every minute.

See `docs/notifications-setup.md` for the Telegram and VK connection flows.

## Processes

- Web: `bundle exec rails server`
- Worker: `bundle exec rails reminders:dispatch_loop`
- Release: `bundle exec rails db:migrate release:check`

## Public Access

- Verify PetTag and profile share public pages return `X-Robots-Tag: noindex, nofollow`.
- Verify profile share links expose only selected sections.
- Verify file downloads are disabled unless explicitly allowed.
- Rotate public tokens when a shared link should be invalidated.

## Scenario Sign-Off

- Complete the owner workspace scenario in `docs/pre-release-scenarios.md`.
- Complete the documents scenario in `docs/pre-release-scenarios.md`.
- Complete the notifications scenario in `docs/pre-release-scenarios.md`.
- Complete the PetTag scenario in `docs/pre-release-scenarios.md`.
- Complete the public profile share scenario in `docs/pre-release-scenarios.md`.
