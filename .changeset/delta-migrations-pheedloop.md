---
'@memberjunction/connector-pheedloop': patch
---

Ship the catalog delta migration (V202607032105) — the wave-1/2 metadata fixes
(20 parent declarations, Members.about → 4000, 17 url/email widths, Reports →
Disabled) previously existed only in the authoring JSON and never reached any
tenant's `__mj` catalog: upgrades apply only NEW migrations and the seed was
never regenerated. Generated per the documented pipeline (`mj sync push`
against the released-seed state + `wrap-migration.mjs`), so `mj app upgrade`
now converges existing installs and fresh installs run seed + delta. Also
fixes `Status: "Inactive"` → `"Disabled"` (Inactive violates
CK_IntegrationObject_Status on every MJ database).
