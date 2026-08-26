# Notification Channels Setup

## Telegram

The user-facing flow is intentionally simple: the user selects Telegram, opens the PetJournal bot and presses **Start**. PetJournal receives the chat id through the webhook and creates the notification channel automatically.

Required environment variables:

- `TELEGRAM_BOT_TOKEN` — token created in BotFather.
- `TELEGRAM_BOT_USERNAME` — bot username without or with `@`.
- `TELEGRAM_WEBHOOK_SECRET` — random secret used to verify Telegram webhook requests.
- `TELEGRAM_CONNECTION_SECRET` — optional separate secret for short-lived account-link tokens. If omitted, `SECRET_KEY_BASE` is used.
- `APP_HOST` — public PetJournal host.
- `APP_PROTOCOL` — normally `https`.

After deployment run:

```bash
bundle exec rails notifications:setup_telegram_webhook
```

The task registers:

```text
https://APP_HOST/telegram/webhook
```

Telegram connection links are short-lived and expire after 30 minutes.

## VK

The user may enter any familiar profile form:

```text
skyrusx
@skyrusx
vk.ru/skyrusx
https://vk.ru/skyrusx
id123456
123456
```

PetJournal resolves the profile through VK API and stores the numeric user id internally. The UI continues to show the friendly profile name instead of `peer_id`.

Required environment variables:

- `VK_GROUP_TOKEN` — token of the PetJournal VK community.
- `VK_API_VERSION` — optional, defaults to `5.199`.

The VK user must allow messages from the PetJournal community before the community can deliver reminders to that dialog. A test delivery should be used to verify the connection.

## Email

Production email delivery requires SMTP configuration and a real `MAIL_FROM` address. Test delivery status should only be treated as meaningful when SMTP is configured.

## Web Push

Browser push requires `VAPID_PUBLIC_KEY`, `VAPID_PRIVATE_KEY`, and `VAPID_SUBJECT`.
