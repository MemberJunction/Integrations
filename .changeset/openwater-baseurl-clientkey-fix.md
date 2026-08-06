---
"@memberjunction/connector-openwater": patch
---

Fix the credential schema and error message that made every connection attempt fail.

The credential-type's FieldSchema never declared a `BaseURL` property, even though `GetAuth()` has
always required `Config.BaseURL` — so the connection form was structurally unable to satisfy the
connector's own runtime requirement, regardless of what the user entered.

Also corrects both `BaseURL`'s and `ClientKey`'s descriptions, and the runtime error message thrown
when `BaseURL` is missing. OpenWater's real API host is the SHARED `https://api.secure-platform.com`
(same value for every customer, confirmed live against its own published swagger) — not a per-tenant
subdomain as previously claimed. The tenant's own subdomain (e.g. `your-org.secure-platform.com`) is
instead what `ClientKey` carries, sent as the `X-ClientKey` header to identify the account against
the shared host.

No behavioral change to request logic — `BaseURL` was, and remains, a required config value; only
its documentation and the schema's ability to collect it were wrong.
