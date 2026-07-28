# Blackbaud — Supported & Proven

> **Evidence tier:** 🟡 Honest-NA (untested for a documented, non-defect reason)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —

> 🟡 **Honest-NA:** No live credential was available; test suite is ready. Mock bidirectional 6/6 exists.

## What this connector supports

**84 objects** declared across **777 fields** (source: `metadata/integration/.blackbaud.integration.json`). 43 declare a write path; 41 are read-only (pull). 7 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| acknowledgement | ✓ | `U` | — |
| address | ✓ | `CU` | — |
| alias | ✓ | `CU` | — |
| appeal_attachment | ✓ | `CU` | — |
| appeal_custom_field | ✓ | `CU` | — |
| batch_gift | ✓ | — (read-only) | — |
| campaign_attachment | ✓ | `CU` | — |
| campaign_custom_field | ✓ | `CU` | — |
| consent_category | ✓ | — (read-only) | — |
| consent_channel | ✓ | — (read-only) | — |
| consent_source | ✓ | — (read-only) | — |
| constituent | ✓ | `U` | ✓ |
| constituent_appeal | ✓ | — (read-only) | — |
| constituent_appeal_2 | ✓ | `CU` | — |
| constituent_attachment | ✓ | `CU` | — |
| constituent_campaign | ✓ | — (read-only) | — |
| constituent_code | ✓ | `CU` | — |
| constituent_code_link | ✓ | — (read-only) | — |
| constituent_consent | ✓ | `C` | — |
| constituent_custom_field | ✓ | `CU` | — |
| constituent_custom_field_category | ✓ | — (read-only) | — |
| constituent_fund | ✓ | — (read-only) | — |
| constituent_fundraiser_assignment | ✓ | — (read-only) | — |
| constituent_id_map | ✓ | — (read-only) | — |
| constituent_package | ✓ | — (read-only) | — |
| constituent_relationship | ✓ | — (read-only) | — |
| constituent_solicit_code | ✓ | `CU` | — |
| converted_constituent | ✓ | — (read-only) | — |
| country | ✓ | — (read-only) | — |
| education | ✓ | `CU` | — |

_First 30 of 84 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed** in either proof DB at generation time.

### Push (write / bidirectional)

- **Status: Mock-verified.** Mock only; no live credential.
- **Mock evidence:** write proven **6/6** against the mock vendor server only — NOT a live tenant.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
