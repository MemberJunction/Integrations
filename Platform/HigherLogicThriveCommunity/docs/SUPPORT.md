# Higher Logic Thrive — Supported & Proven

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —

> 🟡 **Honest-NA:** Built (35-object catalog); not live-tested in this campaign.

## What this connector supports

**35 objects** declared across **584 fields** (source: `metadata/integration/.higher-logic-thrive-community.integration.json`). 14 declare a write path; 21 are read-only (pull). 14 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Announcements | ✓ | — (read-only) | ✓ |
| Answers | ✓ | `CUD` | ✓ |
| AutomationRuleContactData | ✓ | — (read-only) | ✓ |
| AutomationRuleSchedules | ✓ | — (read-only) | — |
| BlogComments | ✓ | `CUD` | — |
| Blogs | ✓ | `CUD` | ✓ |
| Comments | ✓ | `CUD` | — |
| Communities | ✓ | — (read-only) | — |
| CommunityInvitations | ✓ | — (read-only) | ✓ |
| CommunityMembers | ✓ | — (read-only) | — |
| Contacts | ✓ | — (read-only) | ✓ |
| DataFeed | ✓ | — (read-only) | — |
| DemographicChoices | ✓ | `C` | — |
| DemographicTypes | ✓ | `C` | — |
| DiscussionPosts | ✓ | `CUD` | ✓ |
| Discussions | ✓ | — (read-only) | — |
| DiscussionThreads | ✓ | — (read-only) | ✓ |
| DocumentAttachments | ✓ | `CD` | — |
| EventRegistrants | ✓ | — (read-only) | ✓ |
| Events | ✓ | — (read-only) | ✓ |
| EventSessions | ✓ | — (read-only) | ✓ |
| EventTypes | ✓ | `CUD` | — |
| ExternalActivity | ✓ | `CUD` | — |
| IdeaCategories | ✓ | — (read-only) | — |
| Ideas | ✓ | `C` | ✓ |
| IdeaStatuses | ✓ | — (read-only) | — |
| IdeaVoters | ✓ | — (read-only) | — |
| Questions | ✓ | `CUD` | ✓ |
| RegistrantClasses | ✓ | — (read-only) | — |
| ResourceLibraryDocuments | ✓ | `CUD` | — |

_First 30 of 35 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed** in either proof DB at generation time.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Metadata declares write; not verified.
- **Declared write surface (metadata):** 14 of 35 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 0 of 35 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
