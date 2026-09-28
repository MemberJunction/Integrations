---
"@memberjunction/connector-eventscribe": patch
---

Ship the "Eventscribe API" credential type, and make the connection test pass for a key of any Cadmium product.

**Credential type.** The seed migration pointed the Integration row at credential type `81521198-EB2F-4691-87D0-FAD574914C0D` ("Eventscribe API") but never created it, so every fresh install failed on `FK_Integration_CredentialType` — reproduced on a scratch MemberJunction 5.51 PostgreSQL database. The credential type now ships as `metadata/credential-type` (`APIKey`, required and secret; `eID`, optional, the event id for a multi-event key), and the seed creates it, guarded, before the Integration row that references it (both dialects). A new migration repeats the guarded create for completeness; it is a no-op on every reachable database and never changes an existing row.

**Connection test.** It used to probe one fixed object — the first active one by Sequence, a Scorecard door — so an eventScribe or Education Harvester key failed it, and since discovery and both connection wizards run the test first, those connections could not be created. It now fires one cheap read per product family, in `BaseURLsByFamily` order and one second apart, and passes at the first family that answers. It never probes the vendor's 1-per-minute methods. The message names the family that answered and every family tried, with each failure's status and vendor message.

Not proven live: the connector has never contacted a Cadmium system, so which product a given key covers, and what Cadmium answers for a key used on another product's host, are still unobserved.
