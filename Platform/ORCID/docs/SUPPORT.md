# ORCID — Supported & Proven

> **Evidence tier:** 🥇 Production-live (real production system, real data)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48
>
> **Known issues:** In production use with a client today, and still needs work — treat it as live but not finished. The single-record-fetch model (1.3.0) and the flattened fields and person-section objects it added have not yet been run against a live tenant; the proof below predates them.

## What this connector supports

**18 objects** declared across **413 fields** (source: `metadata/integration/.orcid.integration.json`). 0 declare a write path; 18 are read-only (pull). 18 support incremental sync.

Only the `record` object calls ORCID (`GET /{iD}/record`). Every other object is **derived** from the stored record — its `activities-summary` and `person` blocks — with no API call of its own, so a sync costs one request per person rather than one per section per person. The derived objects carry flat, column-shaped fields (source, organization, partial dates, titles, amounts, review subject) beside the nested json ORCID returns.

A person whose stored row lacks the block a section needs is fetched live (`RECORD_FALLBACK_FETCH`), at most 10 per page. If the stored records can't be read at all, every person is fetched live and the cause is reported once per scan (`RECORD_READBACK_FAILED`). A person ORCID will never serve — locked or deactivated (409), gone (410), merged into another iD (301) — is treated as having nothing to sync and reported once per run (`ID_UNAVAILABLE`, naming the surviving iD for a merge). A person who can't be read for any other reason (`ID_FETCH_FAILED`) makes that object's fetch end with an error, on purpose: the engine then keeps the existing rows instead of treating them as deleted, and reads the person again next run.

Pages are sized so a scan stays under 4,000 pages (the engine stops an object at 5,000): 10 people per `record` page up to 40,000 iDs, growing to 50 per page at 200,000. A larger universe is reported as `UNIVERSE_EXCEEDS_RUN`; split it across connections.

### Upgrading a connection set up before 1.3.0

Its record rows have `person` but no `activities-summary`. Until they are refreshed, every activity section reads each person live, which is the pre-1.3.0 call cost. To go straight to the one-call model:

1. Map the record object's `activities-summary` field (and the six new person-section objects, if wanted).
2. Run the `record` object once on its own.
3. Sync the sections as usual. They now read from storage.

Skipping these steps is safe, just slow.

| Object | Source | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|---|
| record | `GET /{iD}/record` | ✓ | — (read-only) | ✓ |
| works | derived (`activities-summary.works`) | ✓ | — (read-only) | ✓ |
| employments | derived (`activities-summary.employments`) | ✓ | — (read-only) | ✓ |
| educations | derived (`activities-summary.educations`) | ✓ | — (read-only) | ✓ |
| qualifications | derived (`activities-summary.qualifications`) | ✓ | — (read-only) | ✓ |
| distinctions | derived (`activities-summary.distinctions`) | ✓ | — (read-only) | ✓ |
| invited-positions | derived (`activities-summary.invited-positions`) | ✓ | — (read-only) | ✓ |
| memberships | derived (`activities-summary.memberships`) | ✓ | — (read-only) | ✓ |
| services | derived (`activities-summary.services`) | ✓ | — (read-only) | ✓ |
| fundings | derived (`activities-summary.fundings`) | ✓ | — (read-only) | ✓ |
| peer-reviews | derived (`activities-summary.peer-reviews`) | ✓ | — (read-only) | ✓ |
| research-resources | derived (`activities-summary.research-resources`) | ✓ | — (read-only) | ✓ |
| other-names | derived (`person.other-names`) | ✓ | — (read-only) | ✓ |
| keywords | derived (`person.keywords`) | ✓ | — (read-only) | ✓ |
| email | derived (`person.emails`) | ✓ | — (read-only) | ✓ |
| address | derived (`person.addresses`) | ✓ | — (read-only) | ✓ |
| researcher-urls | derived (`person.researcher-urls`) | ✓ | — (read-only) | ✓ |
| external-identifiers | derived (`person.external-identifiers`) | ✓ | — (read-only) | ✓ |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| employments | Proven | 38 | MJ_CT48 |
| fundings | Proven | 7 | MJ_CT48 |

**Total proven rows: 45** across 2 distinct objects.

These rows were pulled by the per-section fetch model (pre-1.3.0). The derived model, the flattened
fields and the six person-section objects are verified against ORCID's published sample record
(`src/__tests__/fixtures/record-0000-0002-1825-0097.json`, every envelope shape) in the unit suite,
not yet against a live tenant.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Write not verified.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- **Live run of the derived model** — the read-back of stored records through the engine's entity/field maps has not been exercised against a real tenant on either SQL dialect.
- **A persistently failing iD** (one ORCID answers with a 5xx run after run — locked, deactivated and merged records are handled as unavailable, not failures) fails its object's fetch on every run, so delete detection never runs for that object until the iD is removed from scope or starts answering. That is deliberate (keeping rows beats deleting live ones), but such iDs should be watched for in the `ID_FETCH_FAILED` warnings.
- **Larger pages under throttling** — above 40,000 iDs the root page grows past 10; if ORCID throttles hard enough that the rate limiter backs far off, a large page can exceed the engine's 30s call limit and be retried.
- **Funding `amount`** — exists only on ORCID's per-item detail endpoint, so it is null on a derived item. A detail pass is a future opt-in.
- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — the concurrent root page is governed by the engine's adaptive limiter, but not stress-tested live.
- **Storage** — the record row now holds the full `activities-summary` block (plus the engine's snapshot copy); a prolific author's row runs to several hundred KB. A production consumer saw its database roughly double over ~40k records.

---

_Capability section derived from this connector's own metadata on 2026-10-18. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
