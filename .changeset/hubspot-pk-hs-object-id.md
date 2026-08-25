---
"@memberjunction/connector-hubspot": patch
---

Fix: HubSpot CRM objects now declare **`hs_object_id`** as the primary key instead of **`id`**, matching the field the connector actually populates.

The static metadata declared `id` as the PK on 33 CRM objects, but the connector's `DiscoverFields` declares (and the sync path populates) **`hs_object_id`** — the top-level `id` column is never written. With `id` as the PK, every generated `spCreate` read-back (`WHERE id = @id`) matched nothing (`@id` NULL → SQL `NULL = NULL` is never true) → `"no rows returned"` → **0 rows synced**, silently, for those objects.

This corrects the PK to `hs_object_id` on the 33 affected CRM objects (`companies`, `contacts`, `deals`, `tickets`, `notes`, `line_items`, `calls`, `emails`, `meetings`, `tasks`, `leads`, `products`, `quotes`, `orders`, `line_items`, etc.); `id` is kept as a unique, read-only field but no longer the PK. Non-CRM objects (which legitimately key on `id`) are unchanged. Verified on a live sync: contacts/companies/deals/calls now land real rows with zero "no rows returned" errors.
