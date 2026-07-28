# HubSpot — Supported & Proven

> **Evidence tier:** 🟢 Live-vendor (real API + real account)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** MJ_CT48
>
> ⚠️ **Marquee / high-stake connector** — its claims carry more weight, so the proof-vs-stake gap is flagged below.

## What this connector supports

**168 objects** declared across **1353 fields** (source: `metadata/integration/.hubspot.integration.json`). 111 declare a write path; 57 are read-only (pull). 79 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| api_usage | ✓ | — (read-only) | — |
| appointments | ✓ | `CUD` | ✓ |
| associations_companies_appointments | ✓ | `CD` | — |
| associations_companies_calls | ✓ | `CD` | — |
| associations_companies_communications | ✓ | `CD` | — |
| associations_companies_companies | ✓ | `CD` | — |
| associations_companies_contacts | ✓ | `CD` | — |
| associations_companies_courses | ✓ | `CD` | — |
| associations_companies_deals | ✓ | `CD` | — |
| associations_companies_emails | ✓ | `CD` | — |
| associations_companies_invoices | ✓ | `CD` | — |
| associations_companies_meetings | ✓ | `CD` | — |
| associations_companies_notes | ✓ | `CD` | — |
| associations_companies_orders | ✓ | `CD` | — |
| associations_companies_quotes | ✓ | `CD` | — |
| associations_companies_subscriptions | ✓ | `CD` | — |
| associations_companies_tasks | ✓ | `CD` | — |
| associations_companies_tickets | ✓ | `CD` | — |
| associations_contacts_appointments | ✓ | `CD` | — |
| associations_contacts_calls | ✓ | `CD` | — |
| associations_contacts_carts | ✓ | `CD` | — |
| associations_contacts_commerce_payments | ✓ | `CD` | — |
| associations_contacts_communications | ✓ | `CD` | — |
| associations_contacts_companies | ✓ | `CD` | — |
| associations_contacts_contacts | ✓ | `CD` | — |
| associations_contacts_courses | ✓ | `CD` | — |
| associations_contacts_deals | ✓ | `CD` | — |
| associations_contacts_emails | ✓ | `CD` | — |
| associations_contacts_feedback_submissions | ✓ | `CD` | — |
| associations_contacts_invoices | ✓ | `CD` | — |

_First 30 of 168 objects shown, alphabetically. The full catalog is the metadata file cited above._

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

| Object | Label | Rows (DB-verified) | Which DB |
|---|---|---|---|
| deal_pipeline_stages | Proven | 7 | MJ_CT48 |
| deal_pipelines | Proven | 1 | MJ_CT48 |

**Total proven rows: 8** across 2 of 168 declared objects.

**Declared but 0 rows landed (168 of 168, name-matched):** contacts, companies, deals, tickets, products, line_items, quotes, calls, emails, meetings, notes, tasks, postal_mail, communications, orders, carts, invoices, commerce_payments, subscriptions, discounts, fees, taxes, leads, appointments, services, courses, listings, contracts, goal_targets, feedback_submissions, projects, users, deal_splits, associations_contacts_companies, associations_contacts_deals, associations_contacts_tickets, associations_contacts_calls, associations_contacts_emails, associations_contacts_meetings, associations_contacts_notes, associations_contacts_tasks, associations_contacts_communications, associations_contacts_postal_mail, associations_contacts_quotes, associations_contacts_carts, associations_contacts_orders, associations_contacts_invoices, associations_contacts_commerce_payments, associations_contacts_subscriptions, associations_contacts_appointments, associations_contacts_courses, associations_contacts_listings, associations_contacts_services, associations_contacts_leads, associations_contacts_projects, associations_contacts_feedback_submissions, associations_contacts_contacts, associations_companies_contacts, associations_companies_deals, associations_companies_tickets, associations_companies_calls, associations_companies_emails, associations_companies_meetings, associations_companies_notes, associations_companies_tasks, associations_companies_communications, associations_companies_quotes, associations_companies_orders, associations_companies_invoices, associations_companies_subscriptions, associations_companies_appointments, associations_companies_courses, associations_companies_companies, associations_deals_contacts, associations_deals_companies, associations_deals_tickets, associations_deals_calls, associations_deals_emails, associations_deals_meetings, associations_deals_notes, associations_deals_tasks, associations_deals_quotes, associations_deals_line_items, associations_deals_orders, associations_deals_leads, associations_tickets_contacts, associations_tickets_companies, associations_tickets_deals, associations_tickets_calls, associations_tickets_emails, associations_tickets_meetings, associations_tickets_notes, associations_tickets_tasks, pipelines_deals, pipeline_stages_deals, pipelines_tickets, pipeline_stages_tickets, pipelines_leads, pipeline_stages_leads, lists, list_folders, list_memberships, owners, teams, custom_object_schemas, hubdb_tables, hubdb_rows, marketing_events, marketing_event_attendances, marketing_emails, marketing_email_versions, campaigns, campaign_assets, sequences, sequence_steps, sequence_enrollments, custom_event_definitions, custom_event_completions, files, file_folders, timeline_events, conversation_threads, conversation_messages, forecasts, forecast_categories, call_transcriptions, subscription_types, subscription_statuses, blog_posts, blog_post_versions, blog_authors, blog_tags, site_pages, landing_pages, url_redirects, domains, partner_clients, partner_services, workflows, custom_coded_actions, forms, single_send_v4, transactional_smtp_tokens, media_bridge, blog_settings, api_usage, portal_users, user_roles, business_units, currencies, tax_rates, conversation_inboxes, conversation_channels, conversation_inbox_channels, conversation_custom_channels, meeting_scheduler, datasource_ingestion, scim_users, scim_groups, form_submissions, associations_quotes_contacts, associations_quotes_line_items, associations_tickets_feedback_submissions, marketing_aeo_prompts, marketing_aeo_prompt_runs, marketing_aeo_recommendations, settings_teams, webhooks_journal.

> These objects are declared/supported but landed no rows. **This split does NOT distinguish the reasons** — a zero here is one of: (a) **keyless by design** — the object has no derivable PK (soft keys), so the connector cannot sync it and the test suite *deliberately* skips it (common — often the majority); (b) a genuinely **empty test account**; or (c) a **silent empty-pull** (a real gap). Only the test suite's per-run *coverage* cell (`zeroRowReal` vs `zeroRowLegitEmpty` vs keyless-skipped) classifies which is which; absent that, treat these as **Not proven at the data level**, but do **not** read them as failures — most are keyless-by-design.

> ⚠️ **Coverage: 2 of 168 declared objects (PARTIAL).** These rows are real and DB-verified, but come from a fraction of the catalog — this is **NOT** a full-catalog "all objects" run. The other 166 objects are Not tested (some may be empty on this tenant, but that is unproven). A full-catalog re-sweep (now the test suite default) is required before this connector is proven in the full-coverage sense.

### Push (write / bidirectional)

- **Status: Heavily experimental.** Class wires Create + Delete; 111 metadata objects declare write. None verified live or mock. Read proof in this DB is thin (pipelines only) — the marquee field surface (3,012 rows) lives in a separate MJ_Local DB, not re-queried here.
- **Declared write surface (metadata):** 111 of 168 objects declare a substantiated write path (Create/Update/Delete APIPath+Method).
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.
- **Coverage:** 2 of 168 declared objects have proven rows; the remainder are Not tested / Discovered (many may be empty in the test account).

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
