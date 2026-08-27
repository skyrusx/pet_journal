# PetJournal: personal data compliance baseline

Updated: 2026-08-27

This document records the factual privacy scope discovered in the application and the operational actions that must accompany the code in `feature/personal-data-compliance`.

## Current data inventory

### Account

- name;
- email;
- optional phone;
- password hash and Devise recovery/remember tokens;
- profile avatar;
- notification preferences, quiet hours and time zone.

### Pet data and user-provided content

- pet profile, chip/passport numbers and notes;
- journal events, medications, diagnoses/symptoms and veterinarian/clinic information;
- reminders;
- documents and ActiveStorage attachments;
- photos.

Animal health data is not a special category of the human user's personal data merely because it is medical. Uploaded documents or free-text fields can nevertheless contain personal data about people and must be protected as user content.

### PetTag

- public token and PetTag ID;
- public pet information, safety/lost status and notes selected by the owner;
- scan timestamps;
- finder-provided name/contact/message/location and optional geolocation after separate consent;
- notification delivery state.

Plain PetTag scans no longer persist User-Agent or referrer. Human owner name/phone are not published by PetTag in this compliance baseline.

### Temporary public profile sharing

- unguessable public token and configured pet sections;
- view timestamp;
- truncated User-Agent/referrer;
- anonymized viewer IP;
- optional pet journal/documents/reminders according to the owner's share settings.

The owner's account email and PetTag phone are fail-closed and are not exposed by public sharing until a dedicated lawful public-contact disclosure flow exists.

### Notification channels

The project contains email, Telegram, VK and Web Push delivery capabilities. Channel addresses/identifiers and notification payloads can be personal data. Before enabling a provider in production, confirm the provider, processing location, contractual role and whether a cross-border transfer is involved.

## Legal documents and evidence

Public pages:

- `/privacy` — policy in relation to personal data processing;
- `/personal-data-consent` — separate registration consent;
- `/pet-tag-data-consent` — separate consent for a finder who submits data through PetTag.

Registered-user consent evidence is stored in `user_consents` with document version, acceptance time, source, IP address and User-Agent. PetTag finder consent evidence is stored on the corresponding `pet_tag_scans` record with consent version, policy version and acceptance time.

Document versions are defined in `LegalDocuments`. A material change that affects the substance of a consent must receive a new document version; do not silently edit the meaning of an already accepted version.

## Public contact disclosure

The old `show_phone` and `show_owner_contact` flags were not sufficient evidence of a separate consent for personal data intended for dissemination. Deployment therefore resets those flags to false and controllers reject attempts to re-enable them.

Do not restore public owner phone/name/email with a simple checkbox. A future implementation must be designed specifically around Article 10.1 of Federal Law No. 152-FZ and the then-current Roskomnadzor requirements for consent to dissemination, including exact operator/resource/data details and the subject's ability to set restrictions and conditions.

## Production configuration

Required by `bin/rails release:check`:

- `LEGAL_OPERATOR_NAME` — actual operator name/FIO;
- `LEGAL_OPERATOR_EMAIL` — real address for personal-data requests.

Optional:

- `LEGAL_OPERATOR_DETAILS` — public operator details that are appropriate for the operator's legal form.

Never deploy the legal pages with placeholder operator information.

## Roskomnadzor actions outside the codebase

Before treating this work as operationally complete:

1. Determine the exact operator identity and legal form.
2. Submit or update the notification of personal-data processing under Article 22 of Federal Law No. 152-FZ. PetJournal is an automated public internet service; do not rely on the historical exceptions repealed in 2022.
3. Describe each processing purpose separately and, for each purpose, list subject categories, data categories, legal grounds, actions and processing method.
4. Record the location of databases containing personal data of Russian citizens.
5. Provide the security information required by the current notification form.
6. If any configured provider creates a cross-border transfer, complete the separate Article 12 assessment/notification before the transfer starts.
7. Keep the Roskomnadzor notification current when processing purposes, locations, processors or cross-border transfers materially change.

## NetAngels / infrastructure verification

Obtain written or account-level confirmation for production that:

- PostgreSQL containing user data is physically hosted in Russia;
- ActiveStorage `local` files are stored on Russian infrastructure;
- Redis/cache/queue infrastructure that can contain personal data is hosted in Russia;
- database, file and platform backups remain in Russia and have a defined retention cycle;
- application/access logs are stored in Russia, access-controlled and retained for a defined period;
- the SMTP provider and its server location are known;
- administrative access to hosting, database, backups and files is limited to authorized people;
- deletion from the live application has a documented relationship with backup expiration.

`ACTIVE_STORAGE_SERVICE=local` is only a Rails configuration fact; it is not proof of the physical country in which NetAngels stores the files or backups.

## Security/privacy controls checked in this branch

- HTTPS is forced by the current production Rails configuration;
- Devise stores password hashes rather than plaintext passwords;
- sensitive request parameters are filtered from Rails logs;
- consent acceptance is checked server-side, not only via HTML `required`;
- registration consent is recorded in the same user-creation transaction;
- public legal pages are available without authentication;
- public PetTag/profile-share pages set `X-Robots-Tag: noindex, nofollow`;
- legacy public human contact flags are disabled fail-closed;
- PetTag finder data requires a separate consent before persistence;
- plain PetTag scanning was reduced to data needed for the scan event rather than browser-identifying metadata.

## Follow-up work intentionally outside this baseline

- a compliant public-contact dissemination consent flow for PetTag/profile sharing;
- cookie/analytics consent if non-essential analytics or advertising technologies are added;
- per-provider cross-border assessment for Telegram/Web Push or future external services;
- a formal retention schedule and automated cleanup for logs, finder contacts and backups;
- data export / self-service privacy request center;
- legal CMS or automated re-consent workflow;
- full organizational security documentation and threat-model/pentest work.

## Primary legal references reviewed

- Federal Law No. 152-FZ, Article 9 — consent and separate presentation of consent;
- Federal Law No. 152-FZ, Article 10.1 — personal data permitted by the subject for dissemination;
- Federal Law No. 152-FZ, Articles 18 and 18.1 — operator duties, localization and publication of the policy;
- Federal Law No. 152-FZ, Article 19 — security measures;
- Federal Law No. 152-FZ, Article 22 — notification of processing;
- Federal Law No. 152-FZ, Article 12 — cross-border transfers;
- Roskomnadzor Order No. 18 dated 2021-02-24 — requirements for dissemination consent, effective until 2027-09-01 under the current text.
