---
'@memberjunction/connector-elevate': patch
---

Read the site root from `endpoint`, and say what actually failed.

A connection created through the standard credential UI could not be saved. `TestConnection`
reported:

> The Report API door rejected a minimal query for resource "ProductRegistration". Check the site
> URL and the API key issued for this site.

Both named suspects were innocent, and no HTTP request was ever made. This integration declares
`CredentialTypeID` **"API Key with Endpoint"**, whose schema is `{apiKey, endpoint}` — so the site
root arrives under `endpoint`. `ParseCredentialJSON` accepted `siteUrl`, `SiteUrl`, `site_url`,
`BaseURL`, `baseURL`, `BaseUrl` and `baseUrl`, but not `endpoint`. `SiteUrl` therefore resolved to
`undefined` and `Authenticate` threw *"No Elevate site URL configured"* before reaching the network.
`ValidateResource` caught that, discarded the text, and returned false — which reads as the door
rejecting the query.

The consequence on a live tenant: the same key and host that returned HTTP 200 with real row counts
from `curl` failed in the product, every time, with a message pointing at the credential. Changing
the key could not fix it, because the key was never the problem.

Two changes:

- `endpoint` (plus `Endpoint`, `endpointUrl`, `endpointURL`) is accepted as a site-root alias. It is
  appended to the list, not prepended, so an explicitly configured `siteUrl` still wins and every
  connection that already works is unaffected.
- `TestConnection` now reports the underlying reason instead of a fixed two-suspect sentence.
  `ValidateResource` still never throws and still never deactivates an object, but it remembers why
  the probe failed so the operator is told whether the credential could not be read, the site
  rejected the key, or the host was unreachable — three different faults that were previously
  indistinguishable.

Two tests cover the alias (one mutation-verified against the pre-fix code) and one pins the
precedence.
