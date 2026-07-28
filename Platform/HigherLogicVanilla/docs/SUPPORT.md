# Higher Logic Vanilla — Supported & Proven

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —

> 🟡 **Honest-NA:** Built (65-object catalog); not live-tested in this campaign.

## What this connector supports

**65 objects** declared across **824 fields** (source: `metadata/integration/.higher-logic-vanilla.integration.json`). 54 declare a write path; 11 are read-only (pull). 11 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Addon | ✓ | `U` | — |
| Appeal | ✓ | `CU` | ✓ |
| Article | ✓ | `CU` | — |
| ArticleRevision | ✓ | — (read-only) | ✓ |
| Authenticator | ✓ | `UD` | — |
| AutomationDispatch | ✓ | — (read-only) | ✓ |
| Badge | ✓ | `CUD` | — |
| BadgeRequest | ✓ | `CD` | — |
| Category | ✓ | `CUD` | — |
| Collection | ✓ | `CUD` | ✓ |
| Comment | ✓ | `CUD` | ✓ |
| CommentReaction | ✓ | `CD` | — |
| Conversation | ✓ | `C` | — |
| ConversationParticipant | ✓ | `C` | — |
| DataSource | ✓ | `CUD` | — |
| Discussion | ✓ | `CUD` | ✓ |
| DiscussionReaction | ✓ | `CD` | — |
| Draft | ✓ | `CUD` | ✓ |
| EmailTemplate | ✓ | `CUD` | — |
| Escalation | ✓ | `CU` | ✓ |
| EscalationLog | ✓ | — (read-only) | ✓ |
| Event | ✓ | `CUD` | — |
| EventParticipant | ✓ | `C` | — |
| Export | ✓ | `D` | — |
| Group | ✓ | `CUD` | — |
| GroupApplicant | ✓ | `CU` | — |
| GroupInvite | ✓ | `CD` | — |
| GroupMember | ✓ | `CUD` | — |
| GroupTag | ✓ | — (read-only) | — |
| Icon | ✓ | `D` | — |

_First 30 of 65 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed** in either proof DB at generation time.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Metadata declares write on many objects; not verified.
- **Declared write surface (metadata):** 54 of 65 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 0 of 65 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
