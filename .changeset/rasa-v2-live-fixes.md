---
"@memberjunction/connector-rasa-io": patch
---

Fixes from the first live run against rasa.io's v2 API (api-dev.rasa.io, 2026-10-20).

- **First sync of the action feeds no longer fails.** rasa.io rejects `created_since` more than 24 months ago (HTTP 400), so the fixed 2000-01-01 starting point is replaced by a rolling 725-day window (`Configuration.maxLookbackDays`). A stored watermark older than the window is moved up to it, with a `WATERMARK_CLAMPED` warning.
- **Auth header:** the token is sent as `Authorization: Bearer` only. The live API rejects the `rasa-token` header that its spec documents.
- **Deleted Contact** is fetched once per List: rasa.io requires `list_id`. Its key is now `list_id + id`.
- **Removed:** `Subscription` (its list endpoint requires a `contact_id`, so a sync would make one request per contact; its create/update writes go with it) and `Integration Run` (internal to rasa.io, per the vendor). 23 objects.
