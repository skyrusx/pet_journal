# Release Checklist

## Required Checks

- `bin/rails test`
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
- Set `TELEGRAM_BOT_TOKEN` if Telegram delivery is enabled.
- Set `VK_GROUP_TOKEN` and `VK_API_VERSION` if VK delivery is enabled.
- Set `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT` for browser push.
- Run `bin/rails reminders:dispatch_loop` as a worker process, or run `bin/rails reminders:dispatch` every minute.

## Processes

- Web: `bundle exec rails server`
- Worker: `bundle exec rails reminders:dispatch_loop`
- Release: `bundle exec rails db:migrate release:check`

## Public Access

- Verify PetTag and profile share public pages return `X-Robots-Tag: noindex, nofollow`.
- Verify profile share links expose only selected sections.
- Verify file downloads are disabled unless explicitly allowed.
- Rotate public tokens when a shared link should be invalidated.
