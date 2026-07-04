---
'@memberjunction/connector-growthzone': patch
---

Ship the catalog delta migration (V202607032106) — the wave-1/2 metadata fixes
(MembershipChange + MembershipStatusLookup `listSupported:false` + gap notes,
25 field-width widenings) never reached tenant `__mj` catalogs because the
seed migration was never regenerated and upgrades apply only NEW migrations.
Generated per the documented pipeline (`mj sync push` against the
released-seed state + `wrap-migration.mjs`); `mj app upgrade` now converges
existing installs, fresh installs run seed + delta.
