---
'@memberjunction/connector-elevate': minor
---

Discover this site's real resource catalog instead of trusting a hand-written list of five.

This connector was built on the premise that Elevate "publishes no describe endpoint", so the
declared metadata was the only truth. The premise is wrong. **Every Elevate site serves a catalog of
its own resources at `<siteUrl>/api/reports`** — the same URL the Report API posts to, fetched with
GET. It needs no API key, and the vendor's own prose on that page is their documented answer to what
a client can query: *"In the docs area for each resource below, you will find Relations."* There is
no JSON alternative; this page is what Cadmium provides.

Measured against one live site, the declared catalog was covering **5 of 23 resources**:

| | declared | site documents |
|---|---|---|
| resources | 5 | **23** |
| AccountingCode | 1 field | 6 |
| EarnedCredit | 2 fields | 27 |
| Product | 3 fields | 38 |
| User | 4 fields | 24 |
| ProductRegistration | 20 fields | 26 |

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
