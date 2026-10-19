---
"@memberjunction/connector-rasa-io": major
---

Move the rasa.io connector to the v2 API only, at rasa.io's direction.

2.x signed in with v1 (`POST /v1/tokens`, username + password + API key) and sent that token to every object, but rasa.io's v2 endpoints don't accept v1 tokens, so every v2 object failed with HTTP 401. 3.0.0 signs in with a v2 **client ID and secret** that the customer generates in the rasa.io dashboard (`POST /v2/tokens`, OAuth2 client-credentials), and reuses the token until shortly before its `expires_in`.

**Breaking:**

- **Credential:** the `rasa.io API` credential now takes `clientId` and `clientSecret`. Existing v1 credentials stop working and must be re-entered.
- **Objects:** the 18 v1 objects (Person and its children, Post, Lead Post, Content Pool Item, Community, Section, Insight Action / Topic / Topic Score, Analytics Activity / Article / Image / Topic) are retired. Their destination tables and data are left in place.
- **Actions:** the 12 Actions on Person, Post, Insight Action and Insight Topic are disabled. New read-only Get / Search / List Actions are added for Contact and Newsletter Action.

**New objects:** Newsletter / Blast / Sequence Action (rasa.io's bulk engagement feeds: opens, clicks, deliveries; incremental on `created`), Newsletter / Blast / Sequence Contact, Newsletter Deleted Contact, Segment and Integration Run. The first sync sends an early `created_since`, because rasa.io otherwise defaults it to the last seven days.

Discovery no longer lists undeclared parent-scoped endpoints, which couldn't be synced. Upgrade steps are in `MIGRATION-v3.md`.
