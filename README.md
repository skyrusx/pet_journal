# PetJournal

PetJournal is a Rails app for pet care history, reminders, documents, PetTag safety profiles, and temporary public profile sharing.

## Local Development

Requirements:

- Ruby `3.2.2`
- PostgreSQL
- Bundler

Setup:

```sh
bin/setup
bin/rails db:prepare
bin/rails server
```

Run checks:

```sh
bin/rails test
bin/rubocop
bin/brakeman --no-pager
bin/importmap audit
```

## Production Runtime

Required environment:

- `APP_HOST`
- `SECRET_KEY_BASE`
- `DATABASE_URL` or `PET_JOURNAL_DATABASE_PASSWORD`
- `MAIL_FROM`
- `SMTP_ADDRESS`
- `SMTP_DOMAIN`
- `SMTP_USER_NAME`
- `SMTP_PASSWORD`

Optional notification environment:

- `TELEGRAM_BOT_TOKEN`
- `VK_GROUP_TOKEN`
- `VK_API_VERSION`
- `VAPID_PUBLIC_KEY`
- `VAPID_PRIVATE_KEY`
- `VAPID_SUBJECT`

Operational environment:

- `ACTIVE_JOB_QUEUE_ADAPTER`, defaults to `inline` in production
- `ACTIVE_STORAGE_SERVICE`, defaults to `local`
- `REMINDER_DISPATCH_INTERVAL`, defaults to `60` seconds
- `RAILS_LOG_LEVEL`, defaults to `info`

Validate production configuration:

```sh
bin/rails release:check
```

## Processes

The app expects separate web and worker processes:

```sh
bundle exec rails server
bundle exec rails reminders:dispatch_loop
```

`reminders:dispatch_loop` continuously sends due reminders and retries pending failed deliveries. For cron-style platforms, run `bin/rails reminders:dispatch` every minute instead.

## Deployment

Run migrations and release checks before serving traffic:

```sh
bin/rails db:migrate release:check
```

The Docker image uses `bin/docker-entrypoint`, which runs `db:prepare` for the web process.
