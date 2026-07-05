---
"@memberjunction/connector-eventbrite": major
---

Eventbrite connector v2.0.0 — full rebuild superseding the prior 18-object build.

Breaking: the object set and IO naming changed (33 syncable objects, spaced display
names e.g. "Event Team"/"Inventory Tier" vs the prior "EventTeam"/"InventoryTier"), so
existing 1.0.0 installs' data mappings do not carry over — a major bump.

- 33 Integration Objects (was 18) with per-operation CRUD, continuation-token pagination,
  and `changed_since` incremental sync on Attendee/Order.
- Nested/array fields typed `json` (NVARCHAR MAX); `GetBaseURL` config override for
  region/test endpoints.
- Regenerated seed migration (SQL Server + PostgreSQL), install-tested: seeds 1 Integration
  + 33 Objects + 346 Fields into the core `__mj` catalog.
- Proven end-to-end through the real MJ IntegrationEngine (credential-free e2e = ok:true,
  all objects landing rows, writes round-tripping, watermark/content-hash/delta all green).
