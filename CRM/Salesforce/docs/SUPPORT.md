# Salesforce — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —
>
> ⚠️ **Marquee / high-stake connector** — its claims carry more weight, so the proof-vs-stake gap is flagged below.

## What this connector supports

**1695 objects** declared across **31465 fields** (source: `metadata/integration/.salesforce.integration.json`). 1175 declare a write path; 520 are read-only (pull). 1695 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| AbnExperiment | ✓ | — (read-only) | ✓ |
| AbnExperimentCohort | ✓ | — (read-only) | ✓ |
| AcceptedEventRelation | ✓ | — (read-only) | ✓ |
| Account | ✓ | `CUD` | ✓ |
| AccountBrand | ✓ | `CUD` | ✓ |
| AccountCleanInfo | ✓ | `U` | ✓ |
| AccountContactRelation | ✓ | `CUD` | ✓ |
| AccountContactRole | ✓ | `CUD` | ✓ |
| AccountInsight | ✓ | — (read-only) | ✓ |
| AccountOwnerSharingRule | ✓ | `CUD` | ✓ |
| AccountPartner | ✓ | `CD` | ✓ |
| AccountPlan | ✓ | `CUD` | ✓ |
| AccountPlanObjective | ✓ | `CUD` | ✓ |
| AccountPlanObjectiveMeasure | ✓ | `CUD` | ✓ |
| AccountPlanObjMeasCalcCond | ✓ | `CUD` | ✓ |
| AccountPlanObjMeasCalcDef | ✓ | `CUD` | ✓ |
| AccountPlanObjMeasCalcDefLocalization | ✓ | `CUD` | ✓ |
| AccountPlanObjMeasRela | ✓ | `CUD` | ✓ |
| AccountRelationship | ✓ | `CUD` | ✓ |
| AccountRelationshipShareRule | ✓ | `CUD` | ✓ |
| AccountShare | ✓ | `CUD` | ✓ |
| AccountTag | ✓ | `CD` | ✓ |
| AccountTeamMember | ✓ | `CUD` | ✓ |
| AccountTerritoryAssignmentRule | ✓ | `CUD` | ✓ |
| AccountTerritoryAssignmentRuleItem | ✓ | `CUD` | ✓ |
| AccountTerritorySharingRule | ✓ | `CUD` | ✓ |
| AccountUserTerritory2View | ✓ | — (read-only) | ✓ |
| ActionCadence | ✓ | `UD` | ✓ |
| ActionCadenceRule | ✓ | `CUD` | ✓ |
| ActionCadenceRuleCondition | ✓ | — (read-only) | ✓ |

_First 30 of 1695 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed** in either proof DB at generation time.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Auth is PROVEN against the live dev org: the connector live-discovered 692 objects and field-described them (both require valid auth), and the MJCentral consumer path returned ok=true — picker/persistence/case-insensitive-join all green. A seed additionally wrote 325 records live (Account 50, Contact 100, Opportunity 50, Case 25, Lead 60, Task 40) via the seeder. RESIDUAL GAP: no persisted data-pull landed rows into a salesforce.* schema in the queried DBs — the e2e pull runs errored on a metadata IO-collision (1695 pre-persisted objects) in the shared campaign DB, a test suite issue, not a connector fault. Connector-side write not separately isolated.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
