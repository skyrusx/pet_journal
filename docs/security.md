# PetJournal security baseline

This document describes the first anti-bot / anti-spam layer implemented in `feature/security`.

## Public surface audit

| Endpoint | Risk | Protection |
| --- | --- | --- |
| `POST /register` | automated account creation | IP rate limit + honeypot + form timing signal |
| `POST /login` | brute force / credential stuffing | IP rate limit + normalized-email rate limit |
| `POST /password` | password-reset email spam / account enumeration | IP rate limit + normalized-email rate limit + Devise paranoid responses |
| `GET /p/:token` | scan spam, notification spam, unnecessary scan records | IP rate limit |
| `POST /p/:token/location` | spam messages to a pet owner | IP rate limit + PetTag-token rate limit + honeypot + form timing signal |
| `GET /share/:token` | view-record spam / unnecessary database writes | IP rate limit |
| `POST /telegram/webhook` | machine-to-machine webhook abuse | existing `X-Telegram-Bot-Api-Secret-Token` verification; intentionally excluded from user-form throttles |

Read-only landing, legal, health and PWA endpoints do not create user content or outbound notifications and are not given application-level throttles in this baseline.

## Limits

- registration: 5 requests / 10 minutes / IP;
- login: 20 requests / 5 minutes / IP and 10 requests / 10 minutes / normalized email;
- password reset: 5 requests / hour / IP and 3 requests / hour / normalized email;
- public PetTag page: 30 requests / 5 minutes / IP;
- PetTag finder submission: 10 requests / 10 minutes / IP and 5 requests / 10 minutes / PetTag token;
- public profile share: 60 requests / 5 minutes / IP.

Email addresses and PetTag tokens are SHA-256 hashed before they are used as rate-limit discriminators. Public PetTag/share tokens are filtered from security log paths.

Rack::Attack uses the current Rails cache. The present PetJournal Puma setup runs a single application process, so an in-process cache is sufficient for this baseline. If multiple Puma workers or application instances are introduced, move the Rack::Attack counters to a shared cache such as Redis so all processes enforce the same limits.

## Public form checks

User-fillable public forms use two passive checks:

1. a visually hidden honeypot field; a filled honeypot is rejected with HTTP 422;
2. a signed form timestamp; missing, invalid or unrealistically fast timing is logged as suspicious but does not block a user by itself.

The timing check is intentionally only a signal in this baseline to avoid false positives.

## 429 response

Throttled browser requests receive `public/429.html` and HTTP `429 Too Many Requests` with a `Retry-After` header. Requests accepting JSON receive a small JSON error body instead.

## Logging

Rate-limit and suspicious-form events are written to Rails logs with the request IP, HTTP method, sanitized path and matching rule/reason. Raw email addresses and public access tokens are not logged by the security layer.

## Devise note

The current `User` model does not use Devise `:confirmable`, so there is no confirmation-email resend endpoint to protect yet. If email confirmation is introduced later, add rate limits for the confirmation/resend flow at the same time.

## Deferred protections

Not part of this baseline:

- Cloudflare Turnstile;
- bot scoring;
- manual/automatic IP bans;
- `/admin/security` analytics;
- external reputation/fingerprinting services.

These should be added only if production traffic shows that the baseline is insufficient.
