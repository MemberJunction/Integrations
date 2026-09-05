# @memberjunction/connector-elevate

## 0.3.5

### Patch Changes

- cc1228d: Chunked-fetch salvage: a report that dies with an unexplained 500 (some sites kill any report that generates too long — report cost is additive per column) is now fetched in primary-key-joined field chunks instead of being given up. A column whose report dies even when requested alone is quarantined for the connection with a loud warning and the rest of the object still syncs; the proven chunking is remembered per connection+object so later fetches skip the doomed full request. Keyless objects refuse chunk-joining (row order across separate reports is not a contract) and keep the original error, saying why.

## 0.3.4

### Patch Changes

- a3f5dec: Window filters go out in the vendor's own documented form — comparison-operator keys with full datetimes ({">=": "2021-04-06 00:00:00", "<=": …}) — replacing an invented { date: [from, to] } shape the door silently matched nothing against: every windowed read returned zero rows on tables holding tens of thousands, across three different watermark fields, live.

## 0.3.3

### Patch Changes

- 1a012f9: Discovered objects read through the declared access path that surfaced them (their persisted APIPath is engine-stamped, not authored — trusting it sent reads to nonexistent doors); labels-dictionary names become queryable columns only once streamed row data proves them; the fields allow-list carries only requestable names while embedded extras still land from the raw row; one bounded retry on unexplained 500s; first-contact objects stream via a route synthesized from the site's own catalog. Metadata: EarnedCredit and ProductRegistration gain incremental watermark fields (updated_at / transaction_at) with the matching delta migration.

## 0.3.2

### Patch Changes

- 2480e8e: Let a runtime-discovered object be queried, using the resource name the site itself published

  `DiscoverObjects` reads this site's `/api/reports` catalog and adds every resource the declared
  catalog omits. Those objects have no declared Configuration at all — the page gives a name and a
  field list, nothing else — so `ReadRouteFor` could not resolve a `resourceWireValue` and threw.

  The consequence was that every discovered object was born unqueryable: `DiscoverFieldsViaFetch`
  failed, no fields were ever learned, and the object surfaced in the table picker reading "No fields
  found for this table" with no path to ever sync. On a live tenant that was 18 of 23 objects, while
  the 5 declared ones worked normally — which made a working discovery look like a broken one.

  `ReadRouteFor` now resolves the wire value from three sources in order: the declared
  `resourceWireValue`, the declared access path's own body selector, and finally the resource name
  this site returned from `/api/reports`.

  The refusal is deliberately unchanged for anything the catalog does NOT list. It exists because the
  vendor's own prose spells the accounting resource "accountCode", which the door rejects with HTTP
  500 — only "accountingCode" works. The catalog is the opposite kind of evidence: the site returns
  the string verbatim rather than describing it in prose, and `CatalogResource.Name` is already
  documented as the wire value for the request body's `resource` field. A name absent from the
  catalog is still an unproven guess and is still refused.

  Matching is case-insensitive, but the string sent is the catalog's exact spelling — the wire value
  is what the site said, not what the IntegrationObject happens to be called. A declared wire value
  always wins; the catalog is consulted only when the declaration is silent.

## 0.3.1

### Patch Changes

- a08e8d2: Isolate an unusable column by bisection instead of discarding the whole batch.

  Verification asks the door for every runtime-discovered column in one query. When it refuses, the
  connector drops the field the vendor NAMES and retries. This door names nothing: a bad field name
  comes back as a bare `HTTP 500` with no message, so `Classification.UnknownField` is null, and the
  whole batch was abandoned on the first refusal.

  Live consequence on a tenant: 32 discovered columns on one object and 26 on another, verified NONE,
  every run — the same few unusable names poisoned the same batch each time. The objects still synced
  on their declared columns (2 and 4 respectively), so the loss was invisible: no error, no missing
  data, just a permanently narrow read surface.

  The names are not junk. `LearnLabels` reads the door's own `response.labels` dictionary, which mixes
  queryable columns with relation and rollup keys (`user`, `product`, `stats`, `count`). Those are not
  read selectors, and nothing in the name distinguishes them — the only way to know is to ask.

  So the batch is now halved on an unattributed refusal, recursively. A subset of one that still fails
  is the offender and is remembered as rejected, reaching the same terminal state a named rejection
  does, by isolation rather than by the vendor's cooperation. Every column the door accepts is
  verified. Recursion depth is bounded, so a door failing for reasons unrelated to field names (an
  outage mid-verification) costs a bounded number of requests and leaves everything UNVERIFIED rather
  than rejecting good columns one at a time.

  The invariant that made this safe to change is unchanged and still tested: no request that reads
  data ever carries an unproven name, so a bad label can never cost a row.

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
