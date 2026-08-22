# Reply.io — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-08-05  ·  **Proof DB(s):** —

> 🟢 **Run live through AIDP against Blue Cypress's own Reply.io account.** This connector has synced data from the
> vendor's real API using a real account, as part of AIDP (Blue Cypress's AI Data Platform) — not
> against a mock. **Row volumes and per-object counts are not yet recorded in this repo**, so the
> numbers below are stated as pending rather than guessed; the tier reflects that a live sync ran
> and produced data, which is the claim being made.

## What this connector supports

**84 objects** declared across **552 fields** (source: `metadata/integration/.reply.integration.json`). 34 declare a write path; 50 are read-only (pull). 0 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| AiSdrApproval | ✓ | — (read-only) | — |
| AiSdrIntentSignalIndustry | ✓ | — (read-only) | — |
| AiSdrIntentSignalTechnology | ✓ | — (read-only) | — |
| AiSdrKnowledgeBase | ✓ | `CUD` | — |
| AiSdrKnowledgeBaseDocument | ✓ | `CD` | — |
| AiSdrKnowledgeBaseLink | ✓ | `CD` | — |
| AiSdrKnowledgeBaseReengagementCard | ✓ | `CUD` | — |
| AiSdrKnowledgeBaseReplyHandler | ✓ | `CUD` | — |
| AiSdrKnowledgeBaseReplyHandlerMedia | ✓ | — (read-only) | — |
| AiSdrOffer | ✓ | `CUD` | — |
| AiSdrPlaybook | ✓ | `CUD` | — |
| BackgroundJob | ✓ | — (read-only) | — |
| ConditionTemplate | ✓ | — (read-only) | — |
| Contact | ✓ | `CUD` | — |
| ContactAccount | ✓ | `CUD` | — |
| ContactAccountContact | ✓ | — (read-only) | — |
| ContactAccountList | ✓ | `CUD` | — |
| ContactActivity | ✓ | — (read-only) | — |
| ContactBlacklistRuleDomain | ✓ | `CUD` | — |
| ContactBlacklistRuleEmail | ✓ | `CUD` | — |
| ContactBlacklistRuleEmailException | ✓ | `CUD` | — |
| ContactCustomField | ✓ | — (read-only) | — |
| ContactInboxThread | ✓ | — (read-only) | — |
| ContactList | ✓ | `CUD` | — |
| ContactListReference | ✓ | — (read-only) | — |
| ContactSequence | ✓ | — (read-only) | — |
| ContactStatus | ✓ | — (read-only) | — |
| ContactStatusSequence | ✓ | — (read-only) | — |
| CustomField | ✓ | `CUD` | — |
| EmailAccount | ✓ | `CUD` | — |

_First 30 of 84 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **Rows landed from a live sync.** Data has been pulled from the vendor's real API via AIDP and
  persisted. **Counts pending** — not yet captured into this doc, so no row total is claimed here.
- Request shapes conform to the vendor's API contract, and that conformance has now been exercised
  against the live service rather than only against a test double.

### Push (write / bidirectional)

- **Status: Not verified.** No write has been executed against any system, live or mock.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- **Quantified volumes** — a live sync has run and produced data, but per-object row counts have not
  been captured into this doc, so nothing here is re-checkable against a database yet.
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** live sync exercised this connector end to end; per-object proven-row counts across the 84 declared objects are pending capture.

---

_Capability section derived from this connector's own metadata (`gen-baseline-support-docs.mjs`).
There are no proof numbers to re-state: this doc records a build-time floor, not a measured result.
It is superseded the moment a live or mock sync is run and a real SUPPORT.md is written._
