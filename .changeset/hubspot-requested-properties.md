---
"@memberjunction/connector-hubspot": patch
---

Request the HubSpot properties that field maps commonly need, and keep the default property list when mapped fields are requested (#425).

HubSpot only returns the properties a read asks for. The MJ engine does not yet send the mapped source fields (`FetchContext.RequestedSourceFields` is declared but never set), so every full and incremental read asked for the connector's built-in list only, and a mapped property outside it never arrived. The built-in list now includes `hs_primary_associated_company` on deals (the deal's primary company, so a deal can get its account when it is created) and `hubspot_owner_id` and `hs_last_sales_activity_timestamp` on contacts.

When requested fields are passed, they are now added to the built-in list instead of replacing it. Without this, the engine fix would stop unmapped default properties from arriving, and they would drop out of `CustomOverflow`. No migration: these lists only control what is requested, and the catalog fields come from live discovery.
