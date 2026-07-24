# Pre-Release Scenarios

Run these checks before a release candidate is approved.

## Owner Workspace

- Sign in and open the pets list.
- Create or update a pet profile.
- Add a structured journal event with a next action.
- Verify the follow-up reminder is created and visible in reminders.
- Complete the reminder and create a journal entry from the completion.
- Open the pet dashboard and verify the event, reminder state, documents, PetTag, and public access sections are coherent.

## Documents

- Add a document with expiry date.
- Create or sync its journal event.
- Create or sync its expiry reminder.
- Verify document details show the linked event and reminder.
- Verify public profile shares show document files only when downloads are explicitly enabled.

## Notifications

- Configure email, Telegram, VK, and Web Push where environment allows it.
- Run a channel test and verify immediate success or a clear diagnostic error.
- Run `bin/rails reminders:dispatch` and verify due reminders produce delivery history.
- Run `bin/rails reminders:dispatch_loop` in a worker process for continuous dispatch.
- Verify quiet hours prevent sending during the configured window.

## PetTag

- Enable PetTag and open the public QR URL in a signed-out session.
- Verify public pages return `X-Robots-Tag: noindex, nofollow`.
- Enable Lost Mode and verify the public page highlights the lost state.
- Submit finder contact and voluntary location once.
- Verify the owner receives a notification and the PetTag status moves to found.
- Verify repeated finder submissions for the same scan are blocked.

## Public Profile Share

- Create a short-lived share with only selected sections.
- Open it signed out and verify hidden sections and owner contact are not visible.
- Verify views are deduplicated in the same session and IP addresses are masked.
- Disable or rotate the share and verify the old public URL stops working.

## Release Commands

- `bin/rails test`
- `bin/rubocop`
- `bin/brakeman --no-pager`
- `bin/importmap audit`
- `bin/rails release:check`
