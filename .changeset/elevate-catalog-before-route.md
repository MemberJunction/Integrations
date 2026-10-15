---
"@memberjunction/connector-elevate": patch
---

fix(elevate): load the site's `/api/reports` catalog before resolving a discovered object's route.

`FetchChanges` resolved the read route before anything had loaded the per-instance catalog page (the load happened later, in `RequestableSelectorsFor`). The connector instance is new per run, so every config-less discovered object a run started first failed with "declares no Configuration.resourceWireValue" — 6 objects per run on a live tenant. The "no read-surface columns" error now also says which input was empty (columns, requestable, rejected, requested source fields).
