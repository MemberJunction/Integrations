---
"@memberjunction/connector-spektrix-data-feeds": minor
---

New connector: Spektrix Data Feeds (WCF `IDataFeed.GetCustomerData`). Reads the bulk customer base the Spektrix v3 REST API does not expose, in date windows with a stored window-end watermark, through a host-registered client port (the integrator supplies the Data Feeds client). Five objects: Customer, Tag, TagGroup, CustomerMerge, DataProtectionStatement. Applies a per-connection personal-data policy (`piiMode`: raw / pseudonymize / suppress) before any record reaches the engine.
