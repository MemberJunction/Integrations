# Zendesk — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_ALLOWLIST

## What this connector supports

**99 objects** declared across **1183 fields** (source: `metadata/integration/.zendesk.integration.json`). 72 declare a write path; 27 are read-only (pull). 6 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| activities | ✓ | — (read-only) | — |
| approval_requests | ✓ | `C` | — |
| article_attachments | ✓ | `C` | — |
| article_comments | ✓ | `CUD` | — |
| article_labels | ✓ | `D` | — |
| articles | ✓ | `UD` | — |
| asset_types | ✓ | `CUD` | — |
| assets | ✓ | `CUD` | — |
| audit_logs | ✓ | — (read-only) | — |
| audits | ✓ | — (read-only) | — |
| automations | ✓ | `CUD` | — |
| bookmarks | ✓ | `CD` | — |
| brand_agents | ✓ | `D` | — |
| brands | ✓ | `CUD` | — |
| community_posts | ✓ | `CUD` | — |
| community_topics | ✓ | `CUD` | — |
| compliance_deletion_statuses | ✓ | — (read-only) | — |
| custom_field_options | ✓ | `CD` | — |
| custom_object_access_rules | ✓ | `CUD` | — |
| custom_object_fields | ✓ | `CUD` | — |
| custom_object_permission_policies | ✓ | `U` | — |
| custom_object_record_attachments | ✓ | `CUD` | — |
| custom_object_records | ✓ | `CUD` | ✓ |
| custom_objects | ✓ | `CUD` | — |
| custom_roles | ✓ | `CUD` | — |
| custom_statuses | ✓ | `CUD` | — |
| deleted_tickets | ✓ | `D` | — |
| deleted_users | ✓ | `D` | — |
| deletion_schedules | ✓ | `CUD` | — |
| dynamic_content_items | ✓ | `CUD` | — |

_First 30 of 99 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| audits | Proven | 926 | MJ_ALLOWLIST |
| events | Proven | 429 | MJ_ALLOWLIST |
| ticket_metrics | Proven | 277 | MJ_ALLOWLIST |
| tickets | Proven | 277 | MJ_ALLOWLIST |
| activities | Proven | 152 | MJ_ALLOWLIST |
| user_identities | Proven | 152 | MJ_ALLOWLIST |
| users | Proven | 152 | MJ_ALLOWLIST |
| organization_memberships | Proven | 151 | MJ_ALLOWLIST |
| ticket_fields | Proven | 27 | MJ_ALLOWLIST |
| views | Proven | 17 | MJ_ALLOWLIST |
| triggers | Proven | 11 | MJ_ALLOWLIST |
| articles | Proven | 6 | MJ_ALLOWLIST |
| custom_statuses | Proven | 6 | MJ_ALLOWLIST |
| translations | Proven | 6 | MJ_ALLOWLIST |
| community_posts | Proven | 5 | MJ_ALLOWLIST |
| custom_roles | Proven | 4 | MJ_ALLOWLIST |
| macros | Proven | 4 | MJ_ALLOWLIST |
| tags | Proven | 4 | MJ_ALLOWLIST |
| automations | Proven | 3 | MJ_ALLOWLIST |
| community_topics | Proven | 2 | MJ_ALLOWLIST |
| sections | Proven | 2 | MJ_ALLOWLIST |
| user_segments | Proven | 2 | MJ_ALLOWLIST |
| article_labels | Proven | 1 | MJ_ALLOWLIST |
| brands | Proven | 1 | MJ_ALLOWLIST |
| group_memberships | Proven | 1 | MJ_ALLOWLIST |
| groups | Proven | 1 | MJ_ALLOWLIST |
| help_center_categories | Proven | 1 | MJ_ALLOWLIST |
| recipient_addresses | Proven | 1 | MJ_ALLOWLIST |
| sla_policies | Proven | 1 | MJ_ALLOWLIST |
| ticket_form_statuses | Proven | 1 | MJ_ALLOWLIST |
| ticket_forms | Proven | 1 | MJ_ALLOWLIST |

**Total proven rows: 2,624** across 31 of 99 declared objects.

**Declared but 0 rows landed (68 of 99, name-matched):** approval_requests, article_attachments, article_comments, asset_types, assets, audit_logs, bookmarks, brand_agents, compliance_deletion_statuses, custom_field_options, custom_object_access_rules, custom_object_fields, custom_object_permission_policies, custom_object_record_attachments, custom_object_records, custom_objects, deleted_tickets, deleted_users, deletion_schedules, dynamic_content_items, dynamic_content_variants, email_notifications, group_sla_policies, help_center_votes, itam_asset_fields, itam_asset_statuses, locations, macro_attachments, macro_categories, monitored_twitter_handles, omnichannel_routing_queues, organization_fields, organization_merges, organization_subscriptions, organizations, post_comments, post_subscriptions, remote_authentications, requests, resource_collections, routing_attribute_values, routing_attributes, routing_instance_values, satisfaction_ratings, satisfaction_reasons, saved_searches, schedule_holidays, schedules, service_catalog_items, sessions, sharing_agreements, skips, suspended_tickets, target_failures, targets, task_list_templates, task_lists, tasks, ticket_comments, ticket_content_pins, ticket_events, ticket_metric_events, trigger_categories, trigger_revisions, user_fields, user_subscriptions, view_counts, workspaces.

> These objects are declared/supported but landed no rows. **This split does NOT distinguish the reasons** — a zero here is one of: (a) **keyless by design** — the object has no derivable PK (soft keys), so the connector cannot sync it and the test suite *deliberately* skips it (common — often the majority); (b) a genuinely **empty test account**; or (c) a **silent empty-pull** (a real gap). Only the test suite's per-run *coverage* cell (`zeroRowReal` vs `zeroRowLegitEmpty` vs keyless-skipped) classifies which is which; absent that, treat these as **Not proven at the data level**, but do **not** read them as failures — most are keyless-by-design.

> ⚠️ **Coverage: 31 of 99 declared objects (PARTIAL).** These rows are real and DB-verified, but come from a fraction of the catalog — this is **NOT** a full-catalog "all objects" run. The other 68 objects are Not tested (some may be empty on this tenant, but that is unproven). A full-catalog re-sweep (now the test suite default) is required before this connector is proven in the full-coverage sense.

### Push (write / bidirectional)

- **Status: Mock-verified.** Bidirectional proven only against the mock vendor server; no live write.
- **Declared write surface (metadata):** 72 of 99 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **Mock evidence:** write proven **43/43** against the mock vendor server only — NOT a live tenant.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 31 of 99 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
