# PetJournal

PetJournal is a Rails app for pet care history, reminders, documents, PetTag safety profiles, and temporary public profile sharing.

## Local Development

Requirements:

- Ruby `3.1.2`
- PostgreSQL
- Bundler

Local database credentials are loaded from `.env` via `dotenv-rails`. The file is ignored by Git. Example:

```env
PET_JOURNAL_DB_USER=postgres
PET_JOURNAL_DB_PASSWORD=your-local-password
PET_JOURNAL_DB_HOST=localhost
PET_JOURNAL_DB_PORT=5432
```

Optional database name overrides:

```env
PET_JOURNAL_DB_NAME=pet_journal_development
PET_JOURNAL_TEST_DB_NAME=pet_journal_test
```

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
- `DB_CONNECTION_STRING`
- `LEGAL_OPERATOR_NAME`
- `LEGAL_OPERATOR_EMAIL`
- `MAIL_FROM`
- `SMTP_ADDRESS`
- `SMTP_DOMAIN`
- `SMTP_USER_NAME`
- `SMTP_PASSWORD`

Optional legal environment:

- `LEGAL_OPERATOR_DETAILS` — additional operator details rendered on legal pages when needed

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

The release check treats the legal operator name and privacy contact as required production configuration so a deployment cannot silently publish placeholder operator details.

## Legal and privacy documents

The current document versions and effective dates are defined centrally in `LegalDocuments` (`app/services/legal_documents.rb`). A registration consent record stores the exact consent version together with the privacy policy version that was current when the account was created.

Do not hardcode real operator identity or private contact details into templates. Configure them through the production environment and update the document version whenever a change requires a new legal version.

## Web Push

Generate one VAPID key pair for the PetJournal installation:

```sh
bin/rails web_push:vapid
```

Keep the generated private key out of Git. Configure Web Push either with server environment variables:

```sh
VAPID_PUBLIC_KEY=...
VAPID_PRIVATE_KEY=...
VAPID_SUBJECT=mailto:support@pet-journal.ru
```

or with Rails credentials:

```yaml
web_push:
  public_key: "..."
  private_key: "..."
  subject: "mailto:support@pet-journal.ru"
```

The public key is sent to the browser when the user explicitly enables Web Push. The private key is used only by the Rails server when sending notifications. Avoid rotating the VAPID pair after users have subscribed unless you intentionally want browsers to recreate their subscriptions.

Production Web Push requires HTTPS. `localhost` may be used for development because browsers treat it as a secure context.

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
