# Eventbrite — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_ALLOWLIST

## What this connector supports

**33 objects** declared across **346 fields** (source: `metadata/integration/.eventbrite.integration.json`). 18 declare a write path; 15 are read-only (pull). 2 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Attendee | ✓ | — (read-only) | ✓ |
| Attendee Report | ✓ | — (read-only) | — |
| Balance | ✓ | — (read-only) | — |
| Canned Question | ✓ | `CUD` | — |
| Category | ✓ | — (read-only) | — |
| Discount | ✓ | `CUD` | — |
| Display Settings | ✓ | `U` | — |
| Event | ✓ | `CUD` | — |
| Event Capacity Tier | ✓ | `U` | — |
| Event Description | ✓ | — (read-only) | — |
| Event Schedule | ✓ | `C` | — |
| Event Team | ✓ | `C` | — |
| Fee Rate | ✓ | — (read-only) | — |
| Format | ✓ | — (read-only) | — |
| Inventory Tier | ✓ | `CUD` | — |
| Media | ✓ | — (read-only) | — |
| Media Upload | ✓ | `C` | — |
| Order | ✓ | — (read-only) | ✓ |
| Organization | ✓ | — (read-only) | — |
| Organization Member | ✓ | — (read-only) | — |
| Organization Role | ✓ | — (read-only) | — |
| Question | ✓ | `CD` | — |
| Sales Report | ✓ | — (read-only) | — |
| Seat Map | ✓ | `C` | — |
| Structured Content Page | ✓ | `C` | — |
| Subcategory | ✓ | — (read-only) | — |
| Text Overrides | ✓ | `C` | — |
| Ticket Buyer Settings | ✓ | `U` | — |
| Ticket Class | ✓ | `CU` | — |
| Ticket Group | ✓ | `CUD` | — |

_First 30 of 33 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| Subcategory | Proven | 216 | MJ_ALLOWLIST |
| Event | Proven `!` | 200 `!` | MJ_ALLOWLIST |
| Ticket_Class | Proven `!` | 200 `!` | MJ_ALLOWLIST |
| Category | Proven | 21 | MJ_ALLOWLIST |
| Format | Proven | 20 | MJ_ALLOWLIST |
| Venue | Proven | 10 | MJ_ALLOWLIST |
| Organization_Role | Proven | 4 | MJ_ALLOWLIST |
| Canned_Question | Proven | 3 | MJ_ALLOWLIST |
| Organization | Proven | 1 | MJ_ALLOWLIST |
| Organization_Member | Proven | 1 | MJ_ALLOWLIST |
| User | Proven | 1 | MJ_ALLOWLIST |

**Total proven rows: 677** across 11 of 33 declared objects.

> ℹ️ **`!` = round-number worth a glance (2 objects: Event=200, Ticket_Class=200).** These counts are ≥200 and exactly divisible by 100. That is *sometimes* the signature of an un-paged pull cap — so it's flagged for a look — but a round total is **not** itself evidence of truncation, and where the run's `forward.completeness` check passed, the pull was complete and the round number is just the real count. Treat `!` as "confirm, don't assume broken."

**Declared but 0 rows landed (22 of 33, name-matched):** Attendee, Order, Ticket Group, Discount, Inventory Tier, Event Team, Question, Fee Rate, Seat Map, Webhook, Balance, Structured Content Page, Text Overrides, Ticket Buyer Settings, Display Settings, Event Capacity Tier, Event Description, Event Schedule, Sales Report, Attendee Report, Media, Media Upload.

> These objects are declared/supported but landed no rows. **This split does NOT distinguish the reasons** — a zero here is one of: (a) **keyless by design** — the object has no derivable PK (soft keys), so the connector cannot sync it and the test suite *deliberately* skips it (common — often the majority); (b) a genuinely **empty test account**; or (c) a **silent empty-pull** (a real gap). Only the test suite's per-run *coverage* cell (`zeroRowReal` vs `zeroRowLegitEmpty` vs keyless-skipped) classifies which is which; absent that, treat these as **Not proven at the data level**, but do **not** read them as failures — most are keyless-by-design.

> ⚠️ **Coverage: 11 of 33 declared objects (PARTIAL).** These rows are real and DB-verified, but come from a fraction of the catalog — this is **NOT** a full-catalog "all objects" run. The other 22 objects are Not tested (some may be empty on this tenant, but that is unproven). A full-catalog re-sweep (now the test suite default) is required before this connector is proven in the full-coverage sense.

### Push (write / bidirectional)

- **Status: Mock-verified.** Mock bidirectional green; no live write.
- **Declared write surface (metadata):** 18 of 33 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **Mock evidence:** write proven **green** against the mock vendor server only — NOT a live tenant.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 11 of 33 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
