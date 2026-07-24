# Release Checklist

## Required Checks

- `bin/rails test`
- `bin/rubocop`
- `bin/brakeman --no-pager`
- `bin/importmap audit`

## Runtime

- Upgrade Ruby from `3.2.2` to a supported release before production release.
- Upgrade Rails from `7.2.3.1` before its support window ends.

## Environment

- Configure SMTP for email reminders.
- Set `TELEGRAM_BOT_TOKEN` if Telegram delivery is enabled.
- Set `VK_GROUP_TOKEN` and `VK_API_VERSION` if VK delivery is enabled.
- Set `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT` for browser push.
- Run `ReminderDispatchJob` on a recurring schedule.

## Public Access

- Verify PetTag and profile share public pages return `X-Robots-Tag: noindex, nofollow`.
- Verify profile share links expose only selected sections.
- Verify file downloads are disabled unless explicitly allowed.
- Rotate public tokens when a shared link should be invalidated.
