# Hivebrite — Supported & Proven

<!-- baseline-stub: no live or mock sync has been run for this connector. Replace this whole file
     with real evidence when one is, and delete this marker — the overview pages key on it. -->

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** 2026-07-28  ·  **Proof DB(s):** —

> 🟡 **Baseline — format-verified, no credential.** This connector was built through the
> build-connector pipeline for AIDP (Blue Cypress's AI Data Platform), whose default gate is the
> credential-free behavioural matrix: spec-conformance against the vendor's published API contract,
> a mock vendor server exercising pull/push/pagination/incremental shapes, and anti-vacuous
> assertions (a green must mean "observed to work", never "ran without error"). **No live system has
> been contacted and no rows have been persisted.** The reason is a credential gap, not a defect.

## What this connector supports

**98 objects** declared across **1186 fields** (source: `metadata/integration/.hivebrite.integration.json`). 45 declare a write path; 53 are read-only (pull). 23 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Admin | ✓ | `CUD` | — |
| Admin_V1_BusinessOpportunities_ExternalRecruiterEntity | ✓ | — (read-only) | — |
| Admin_V1_Uploads_GlobalStorageEntity | ✓ | — (read-only) | — |
| Admin_V2_EngagementScoring_RankEntity | ✓ | — (read-only) | — |
| Admin_V2_EngagementScoring_RankingEntity | ✓ | — (read-only) | — |
| Admin_V2_EngagementScoring_ScoreEntity | ✓ | — (read-only) | — |
| Admin_V2_MediaCenter_FilesFullEntity | ✓ | `CUD` | — |
| Admin_V2_MediaCenter_FilesShortEntity | ✓ | — (read-only) | — |
| Admin_V2_MediaCenter_FolderEntity | ✓ | `CUD` | — |
| Admin_V2_MediaCenter_FoldersShortEntity | ✓ | — (read-only) | — |
| Admin_V2_MediaCenter_OwnerEntity | ✓ | — (read-only) | — |
| Admin_V2_Memberships_PaymentOptionsEntity | ✓ | `CU` | — |
| Admin_V2_NetworkEvents_WaitlistEntryEntity | ✓ | — (read-only) | — |
| Admin_V2_Users_CurrentLocationEntity | ✓ | — (read-only) | ✓ |
| Admin_V3_AuditLog_ContentEntity | ✓ | — (read-only) | — |
| Admin_V3_AuditLog_IndexEntity | ✓ | — (read-only) | ✓ |
| Admin_V3_Comments_CommentEntity | ✓ | — (read-only) | — |
| Admin_V3_Comments_CommentWithRepliesEntity | ✓ | `CUD` | — |
| Admin_V3_EmailAnalyticsV2_DeliveryEntity | ✓ | — (read-only) | — |
| Admin_V3_Forums_DiscussionEntity | ✓ | `CUD` | — |
| Admin_V3_Likes_SimpleEntity | ✓ | — (read-only) | — |
| Admin_V3_Mentoring_MenteeProfileEntity | ✓ | `CUD` | — |
| Admin_V3_Mentoring_MentorProfileEntity | ✓ | `CUD` | — |
| Admin_V3_Mentoring_ProgramEntity | ✓ | `CU` | — |
| Admin_V3_Mentoring_RelationshipEntity | ✓ | `CUD` | — |
| Admin_V3_NotificationEntity | ✓ | — (read-only) | ✓ |
| Admin_V3_Notifications_NotifierEntity | ✓ | — (read-only) | — |
| Admin_V3_OrderManagement_ManualTransactionEntity | ✓ | `CUD` | — |
| Admin_V3_Posts_PostEntity | ✓ | `CUD` | — |
| Admin_V3_UserData_FieldEntity | ✓ | — (read-only) | — |

_First 30 of 98 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed.** No live or mock sync has been run for this connector; there is no proof DB.
- Build-time verification only: the declared request shapes conform to the vendor's API contract.

### Push (write / bidirectional)

- **Status: Not verified.** No write has been executed against any system, live or mock.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- **Everything beyond format verification** — no credential has been used for this connector, so no
  row count, field-shape sample, or write side-effect has been observed against a real tenant.
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 0 of 98 declared objects have proven rows.

---

_Capability section derived from this connector's own metadata (`gen-baseline-support-docs.mjs`).
There are no proof numbers to re-state: this doc records a build-time floor, not a measured result.
It is superseded the moment a live or mock sync is run and a real SUPPORT.md is written._
