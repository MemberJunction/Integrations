---
"@memberjunction/connector-wild-apricot": minor
---

Three live-verified Wild Apricot fixes (minor because the third changes seeded metadata, generating a new migration):

1. **Auth (code)** — send the literal string `APIKEY` as the HTTP-Basic username and the admin API key as the password (the connector was sending the API key as the username with an empty password). The previous form failed every `client_credentials` token request with `HTTP 401 — invalid_client`, so no data could sync. Corrected → authentication succeeds.

2. **Contacts pagination (code)** — fetch the `Contact` object via Wild Apricot's stable async EXPORT snapshot: kick off `$async=true` once, poll the `ResultId` to `State='Complete'`, then page that immutable snapshot with `?resultId=<id>&$skip&$top`. The previous live `$async=false&$skip` scan is order-unstable when interleaved with the sync's other requests — pages overlap, so only a fraction of contacts dedup through (observed: 197 of 1,275). The export snapshot returns the complete set (verified: full 1,275 contacts sync).

3. **AttachmentData disabled (metadata)** — `AttachmentData` declared a GET list path (`/accounts/{accountId}/attachments/GetInfos`) that returns HTTP 404: Wild Apricot has no account-level "list all attachments" endpoint. Marked `Status='Disabled'` so the sync no longer attempts an un-listable object. (Proper attachment sync via the `POST /attachments/GetInfos` info-lookup remains a future enhancement.)
