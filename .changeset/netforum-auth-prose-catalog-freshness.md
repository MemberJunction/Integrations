---
'@memberjunction/connector-netforum-enterprise': patch
---

Correct the netFORUM Enterprise auth declaration, and pin the declared catalog's freshness.

**The auth prose contradicted the code it cited.** `CredentialType.Description`, the credential
`FieldSchema` field help, and `Integration.Configuration.AuthFlowNote` / `AuthHeaderPattern` /
`AuthHeaderPatternNote` / `TransportMode` / `TransportModeNote` all described a JSON shim: POST to
`<BaseURL>/xWeb/JSON/Authenticate` with HTTP Basic, receive an `Authorization: Bearer <token>` for
later calls. The connector does not do that and never has on this code path.
`NetForumConnector.Authenticate()` POSTs a SOAP `Authenticate(userName, password)` envelope to
`<BaseURL>/xweb/secure/netForumXML.asmx` with the credentials as **body elements** — no HTTP
`Authorization` header is set on that call at all — and reads the token from `AuthenticateResult`.
Every later call carries it as a SOAP **header element**,
`<AuthorizationToken><Token>{token}</Token></AuthorizationToken>`. The connector's own file header
has said so verbatim throughout: *"Auth (TWO-STEP, SOAP — NOT HTTP Basic / WWW-Authenticate /
Bearer)"*.

This is operator-facing, not cosmetic: `CredentialType.Description` and `FieldSchema` are what
someone reads while filling in the credential form, and they are served from the tenant catalog —
so an operator debugging a failed connection was being told to look for a Bearer header that never
appears on the wire. `TransportMode` also moves `soap_with_json_shim` → `soap`; the JSON shim is not
called by this connector and its existence is unverified from this repo.

The old note cited `NetForumConnector.ts:326-357`, a line range that now lands on unrelated code.
The replacement cites **symbols** (`Authenticate()`, `BuildSoapEnvelope()`, `SoapHeaders()`), which
survive edits.

**The declared catalog had no freshness record.** Provenance was three keys buried inside
`WSDLOperationCounts` — the fetch date reading as a footnote to a statistic rather than as the
catalog's evidence base. They move into a `DeclaredAgainst` block (the convention already used by
`LMS/Elevate` and `Platform/WordPress`), which additionally records what is **not** pinned, because
an unrecorded gap reads as a settled fact:

- **no `sha256`** of the 5.94 MB WSDL — a refetch cannot be diffed against what was declared from;
  `totalUniqueOperations` (277) is the only comparable, and a bare count can collide.
- **no `docSitesFetchedAt`** — the Abila 2017.1 pages are cited throughout the Configuration but
  were never date-stamped.
- **no `tenantReleaseVersion`** — the two source WSDLs are live tenant instances of unknown release,
  read against a 2017.1 doc set, so a later "missing" object cannot be attributed (catalog wrong, or
  tenant older?). `Platform/WordPress` pins `wp 7.1` / `woocommerce 11.0.1` with zip sha256s for
  exactly this reason.
- **`catalogLastEditedAt`** — "source fetched" and "catalog edited" are different dates.
  `V202607280915` edited the catalog 37 days after the pin, from the same WSDL read; nothing
  recorded that, so a reader could not tell an evidence-backed edit from a freehand one.

No object rows, field rows, IDs or capability flags change. Reads and writes are unaffected —
this ships declared text only, via delta migration `V202608261200` (+ its Postgres twin).
