# Constant Contact — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —

## What this connector supports

**65 objects** declared across **533 fields** (source: `metadata/integration/.constant-contact.integration.json`). 27 declare a write path; 38 are read-only (pull). 2 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| account_emails | ✓ | `C` | — |
| account_physical_address | ✓ | — (read-only) | — |
| account_summary | ✓ | `U` | — |
| account_user_privileges | ✓ | — (read-only) | — |
| activities | ✓ | — (read-only) | — |
| activities_contacts_delete | ✓ | `C` | — |
| activities_contacts_file_import | ✓ | `C` | — |
| activities_contacts_json_import | ✓ | `C` | — |
| activities_contacts_taggings_add | ✓ | `C` | — |
| activities_contacts_taggings_remove | ✓ | `C` | — |
| activities_contacts_tags_delete | ✓ | `C` | — |
| activities_custom_fields_delete | ✓ | `C` | — |
| activities_list_delete | ✓ | `C` | — |
| activities_list_memberships_add | ✓ | `C` | — |
| activities_list_memberships_remove | ✓ | `C` | — |
| contact_custom_fields | ✓ | `CUD` | — |
| contact_lists | ✓ | `CUD` | — |
| contact_lists_xrefs | ✓ | — (read-only) | — |
| contact_reports_activity_details | ✓ | — (read-only) | — |
| contact_reports_activity_summary | ✓ | — (read-only) | — |
| contact_reports_open_and_click_rates | ✓ | — (read-only) | — |
| contact_tags | ✓ | `CUD` | — |
| contacts | ✓ | `CUD` | ✓ |
| contacts_counts | ✓ | — (read-only) | — |
| contacts_sign_up_form | ✓ | `C` | — |
| contacts_sms_engagement_history | ✓ | — (read-only) | — |
| contacts_xrefs | ✓ | — (read-only) | — |
| email_campaign_activities | ✓ | `U` | — |
| email_campaign_activity_abtest | ✓ | `CD` | — |
| email_campaign_activity_non_opener_resends | ✓ | `CD` | — |

_First 30 of 65 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **No rows landed** in either proof DB at generation time. (Account is near-empty — thin, not a defect.)

### Push (write / bidirectional)

- **Status: Heavily experimental.** Near-empty test account; write unverified.
- **Declared write surface (metadata):** 31 of 65 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
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
