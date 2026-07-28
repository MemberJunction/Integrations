# MagnetMail — Supported & Proven

> **Evidence tier:** 🧪 Mock-only (proven vs mock server, never live)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —

## What this connector supports

**47 objects** declared across **317 fields** (source: `metadata/integration/.magnetmail.integration.json`). 6 declare a write path; 41 are read-only (pull). 0 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| email_history | ✓ | — (read-only) | — |
| Error | ✓ | — (read-only) | — |
| EventSignUp | ✓ | `C` | — |
| ExtendedField | ✓ | — (read-only) | — |
| fax_history | ✓ | — (read-only) | — |
| fieldDefn | ✓ | — (read-only) | — |
| form_history | ✓ | — (read-only) | — |
| group | ✓ | `C` | — |
| GroupCategory | ✓ | — (read-only) | — |
| GroupRecipient | ✓ | — (read-only) | — |
| GroupRecipients | ✓ | — (read-only) | — |
| JobToGroup | ✓ | — (read-only) | — |
| link | ✓ | — (read-only) | — |
| Links | ✓ | — (read-only) | — |
| MagnetMailQueries | ✓ | — (read-only) | — |
| MailRecipientGroup | ✓ | — (read-only) | — |
| Message | ✓ | `CU` | — |
| MessageCategory | ✓ | — (read-only) | — |
| MessageDetails | ✓ | — (read-only) | — |
| MessageLinkTrackingData | ✓ | — (read-only) | — |
| MessageList | ✓ | — (read-only) | — |
| MessageSentTrackingData | ✓ | — (read-only) | — |
| MessageTrackingData | ✓ | — (read-only) | — |
| newsletter | ✓ | — (read-only) | — |
| PaidItem | ✓ | — (read-only) | — |
| PersonifySubscriptionMapping | ✓ | — (read-only) | — |
| QuestionItem | ✓ | — (read-only) | — |
| Recipient | ✓ | `CU` | — |
| recipient_history | ✓ | — (read-only) | — |
| RecipientExtended | ✓ | — (read-only) | — |

_First 30 of 47 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed** in either proof DB at generation time.

### Push (write / bidirectional)

- **Status: Mock-verified.** SOAP connector; write/shape proven against the mock server only.
- **Declared write surface (metadata):** 7 of 47 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **Mock evidence:** write proven **18/19** against the mock vendor server only — NOT a live tenant.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 0 of 47 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
