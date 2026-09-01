# @memberjunction/connector-elevate

## 0.3.0

### Minor Changes

- cb6c89b: Discover this site's real resource catalog instead of trusting a hand-written list of five.

  This connector was built on the premise that Elevate "publishes no describe endpoint", so the
  declared metadata was the only truth. The premise is wrong. **Every Elevate site serves a catalog of
  its own resources at `<siteUrl>/api/reports`** — the same URL the Report API posts to, fetched with
  GET. It needs no API key, and the vendor's own prose on that page is their documented answer to what
  a client can query: _"In the docs area for each resource below, you will find Relations."_ There is
  no JSON alternative; this page is what Cadmium provides.

  Measured against one live site, the declared catalog was covering **5 of 23 resources**:

  |                     | declared  | site documents |
  | ------------------- | --------- | -------------- |
  | resources           | 5         | **23**         |
  | AccountingCode      | 1 field   | 6              |
  | EarnedCredit        | 2 fields  | 27             |
  | Product             | 3 fields  | 38             |
  | User                | 4 fields  | 24             |
  | ProductRegistration | 20 fields | 26             |

  Eighteen resources — `cart`, `payment`, `package`, `category`, `quiz*`, `survey*`, `speaker`,
  `webContent` and more — were invisible, with no error and nothing to notice them. That is the silent
  data-loss shape: a resource the client has and we never mention.

  The page also documents **Relations** per resource (`productRegistration → cart, earnedCredit,
payment, product, quizResult, user`), which is the foreign-key graph this connector previously had
  none of, and which sync ordering depends on.

  **The parse is additive and non-authoritative, by construction.** It is HTML the vendor never
  promised as an API, so:

  - Nothing it returns can remove or deactivate an object. `DiscoveryIsAuthoritative` stays `false`
    and `deactivationPermitted` stays `false` — presence is the only thing this evidence can prove.
  - It is sanity-gated: the result is discarded **whole** unless it documents the resources the
    declared catalog already asserts. A page that parsed to something unrecognisable is a page whose
    shape changed, and half-believing it is worse than ignoring it.
  - Every failure — unreachable, auth-walled, disabled, restructured — falls back to the declared
    catalog with one warning per connection. A deployment that does not serve this page behaves
    exactly as it does today.
  - Discovered resources are read-only and full-sync. The page states no watermark field and no write
    door, and inferring either from a field name is the kind of guess that ships a broken predicate.

  Eleven tests cover the parser against the real page's structure, including relation resolution
  (cells naming non-resources are rejected), header-row exclusion, the gate, and four
  should-return-null shapes.

## 0.2.2

### Patch Changes

- 291eb79: Read the site root from `endpoint`, and say what actually failed.

  A connection created through the standard credential UI could not be saved. `TestConnection`
  reported:

  > The Report API door rejected a minimal query for resource "ProductRegistration". Check the site
  > URL and the API key issued for this site.

  Both named suspects were innocent, and no HTTP request was ever made. This integration declares
  `CredentialTypeID` **"API Key with Endpoint"**, whose schema is `{apiKey, endpoint}` — so the site
  root arrives under `endpoint`. `ParseCredentialJSON` accepted `siteUrl`, `SiteUrl`, `site_url`,
  `BaseURL`, `baseURL`, `BaseUrl` and `baseUrl`, but not `endpoint`. `SiteUrl` therefore resolved to
  `undefined` and `Authenticate` threw _"No Elevate site URL configured"_ before reaching the network.
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

## 0.2.1

### Patch Changes

- 9711c85: Accept a site URL that already carries the door path.

  A tenant supplied `siteUrl` with `/api/reports` on the end — the form the client was given. `GetBaseURL`
  returns `siteUrl` verbatim (it only strips trailing slashes) and `JoinURL` then appends the object's own
  door, so every request went to `…/api/reports/api/reports`. That 404/405s, `ValidateResource` swallows
  the error and returns false, and `TestConnection` reports:

  > The Report API door rejected a minimal query for resource "ProductRegistration". Check the site URL
  > and the API key issued for this site.

  Both named suspects were innocent. The same key against the same tenant reached **every declared
  resource**: ProductRegistration 86,074 rows, EarnedCredit 71,799, User 13,163, Product 132,
  AccountingCode 1 — roughly 171k rows, including `ProductRegistration.amount_discounted`, the exact
  resource and field the failing probe used. The connection simply could not be saved, and the message
  sent the operator to check a credential that was already correct.

  `Authenticate` now normalises the configured value through a `NormalizeSiteUrl` helper that removes a
  trailing door path: `/api/reports`, its `/form` variant, and `/api/registrations` — the three the
  connector can append. Only a WHOLE trailing segment is stripped and the match is case-insensitive, so a
  site genuinely served from a directory (`/lms`, or a path that merely starts with the same letters like
  `/api/reportsdata`) is left exactly as configured.

  Eight tests cover it: each door form and a differently-cased one normalise to the site root; three
  legitimate paths survive untouched; and an end-to-end read asserts the door is appended exactly once
  when `siteUrl` already carried it.

  Behaviour is unchanged for every connection already configured with a bare site root. No metadata,
  objects, fields or capability flags change — this is code only.

## 0.2.0

### Minor Changes

- 06856f3: Elevate LMS connector published as an Open App.
