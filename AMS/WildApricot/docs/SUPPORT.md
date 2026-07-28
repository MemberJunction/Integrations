# Wild Apricot — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48

## What this connector supports

**25 objects** declared across **332 fields** (source: `metadata/integration/.wild-apricot.integration.json`). 14 declare a write path; 11 are read-only (pull). 4 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| Account | ✓ | — (read-only) | — |
| AttachmentData | ✓ | — (read-only) | — |
| AuditLogItem | ✓ | — (read-only) | — |
| Bundle | ✓ | — (read-only) | — |
| CeuRecord | ✓ | `CUD` | — |
| Contact | ✓ | `CUD` | ✓ |
| ContactFieldDescription | ✓ | `CUD` | — |
| Donation | ✓ | `CU` | — |
| EmailDraft | ✓ | `D` | — |
| EmailLog | ✓ | — (read-only) | — |
| EntityFieldDescription | ✓ | `CUD` | — |
| Event | ✓ | `CUD` | — |
| EventRegistration | ✓ | `CUD` | — |
| EventRegistrationType | ✓ | `CUD` | — |
| Invoice | ✓ | `CUD` | ✓ |
| MembershipGroup | ✓ | — (read-only) | — |
| MembershipLevel | ✓ | — (read-only) | — |
| Order | ✓ | — (read-only) | — |
| Payment | ✓ | `CUD` | ✓ |
| PaymentAllocation | ✓ | — (read-only) | — |
| Product | ✓ | `CUD` | — |
| Refund | ✓ | `CUD` | ✓ |
| SavedSearch | ✓ | — (read-only) | — |
| SentEmailRecipient | ✓ | — (read-only) | — |
| Tender | ✓ | `CUD` | — |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| Contact | Proven | 1,275 | MJ_CT48 |

**Total proven rows: 1,275** across 1 of 25 declared objects.

**Declared but 0 rows landed (24 of 25, name-matched):** Account, AttachmentData, AuditLogItem, Bundle, CeuRecord, ContactFieldDescription, Donation, EmailDraft, EmailLog, EntityFieldDescription, Event, EventRegistration, EventRegistrationType, Invoice, MembershipGroup, MembershipLevel, Order, Payment, PaymentAllocation, Product, Refund, SavedSearch, SentEmailRecipient, Tender.

> These objects are declared/supported but landed no rows. **This split does NOT distinguish the reasons** — a zero here is one of: (a) **keyless by design** — the object has no derivable PK (soft keys), so the connector cannot sync it and the test suite *deliberately* skips it (common — often the majority); (b) a genuinely **empty test account**; or (c) a **silent empty-pull** (a real gap). Only the test suite's per-run *coverage* cell (`zeroRowReal` vs `zeroRowLegitEmpty` vs keyless-skipped) classifies which is which; absent that, treat these as **Not proven at the data level**, but do **not** read them as failures — most are keyless-by-design.

> ⚠️ **Coverage: 1 of 25 declared objects (PARTIAL).** These rows are real and DB-verified, but come from a fraction of the catalog — this is **NOT** a full-catalog "all objects" run. The other 24 objects are Not tested (some may be empty on this tenant, but that is unproven). A full-catalog re-sweep (now the test suite default) is required before this connector is proven in the full-coverage sense.

### Push (write / bidirectional)

- **Status: Mock-verified.** Mock bidirectional; no live write.
- **Declared write surface (metadata):** 14 of 25 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **Mock evidence:** write proven **25/25** against the mock vendor server only — NOT a live tenant.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 1 of 25 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
