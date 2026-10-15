# @memberjunction/connector-eventscribe

## 0.3.0

### Minor Changes

- e5b8f65: Keep each event's records apart: every active object gains an `EventScope` field, and on the 17 keyed objects it joins the primary key.

  All connections of one connector write into the same tables, and the engine matches an incoming row to an existing one by the entity's primary key across the whole table. Every key was a Cadmium id alone, so a client with one connection per product per event got one row per id: the same author, presenter or exhibitor in two events became a single row holding whichever event synced last.

  The connector now stamps `EventScope` on every record it reads — list reads, nested door walks and single-record re-reads. The value is the connection's configured `eID` when there is one. With no eID it is the connection's own ID, so two connections share a scope only by naming the same event. An empty value is refused rather than stamped. `ExternalID` stays the vendor key, so update, delete and read-one requests are unchanged, and the stamp is stripped from every outbound write body. The five keyless objects carry `EventScope` as a plain column, which makes their content-hash identity per event too. The connection test says which way the connection will be keyed.

  Ships as `V202609281056__eventscribe__EventScopeKey` (22 new field rows, both dialects; no existing row changes). Set eID before a connection's first sync if you need it: adding one later changes that connection's scope.

### Patch Changes

- df41889: Ship the "Eventscribe API" credential type, and make the connection test pass for a key of any Cadmium product.

  **Credential type.** The seed migration pointed the Integration row at credential type `81521198-EB2F-4691-87D0-FAD574914C0D` ("Eventscribe API") but never created it, so every fresh install failed on `FK_Integration_CredentialType` — reproduced on a scratch MemberJunction 5.51 PostgreSQL database. The credential type now ships as `metadata/credential-type` (`APIKey`, required and secret; `eID`, optional, the event id for a multi-event key), and the seed creates it, guarded, before the Integration row that references it (both dialects). A new migration repeats the guarded create for completeness; it is a no-op on every reachable database and never changes an existing row.

  **Connection test.** It used to probe one fixed object — the first active one by Sequence, a Scorecard door — so an eventScribe or Education Harvester key failed it, and since discovery and both connection wizards run the test first, those connections could not be created. It now fires one cheap read per product family, in `BaseURLsByFamily` order and one second apart, and passes at the first family that answers. It never probes the vendor's 1-per-minute methods. The message names the family that answered and every family tried, with each failure's status and vendor message.

  Not proven live: the connector has never contacted a Cadmium system, so which product a given key covers, and what Cadmium answers for a key used on another product's host, are still unobserved.

## 0.2.1

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

## 0.2.0

### Minor Changes

- 096276d: Eventscribe connector published as an Open App.
