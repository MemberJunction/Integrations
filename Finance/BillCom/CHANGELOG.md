# @memberjunction/connector-bill-com

## 0.3.2

### Patch Changes

- ff57db0: Stop repeating the API version in every URL, and expose invoice archive/restore.

  **The version segment belonged to the path, and the base carried it too.** Every object path in the
  catalog is an OpenAPI path beginning `/v3/…`, while `ResolveBaseURL` returned a gateway already
  ending in `/connect/v3`. The engine builds a request as base + path, so a create went to
  `…/connect/v3/v3/customers` and came back 404 — as did every update, read and fetch. Nothing caught
  it: `Login` is the one endpoint the connector addresses itself, so `TestConnection` reported success
  on a connection where no other verb worked, and the mock suite asserts on request bodies rather than
  URLs. The gateway constants lose the version, `Login` asks for `/v3/login` explicitly, and both
  `ResolveBaseURL` and `GetBaseURL` normalise whatever they are handed — a trailing `/v3` is stripped
  rather than rejected, because `…/connect/v3` is the spelling the credential type's own `apiUrl` help
  text recommends and existing connections are configured that way. Both spellings now resolve to the
  same requests, so no database needs repairing.

  **Cancellation had no supported path.** In BILL, cancelling an AR invoice means archiving it:
  `InvoiceStatus` has no VOID or CANCELED value, and `DeleteRecord` correctly refuses because archive
  is not a delete. The catalog has always declared `archivePath`, `archiveMethod` and `restorePath` on
  the invoices object, but nothing called them. `UpdateRecord({archived: true})` cannot stand in — the
  invoices object updates with `PUT`, and BILL's PUT is a full replace that answers
  `400 customer: must not be null; invoiceLineItems: must not be null`. New `ArchiveInvoice` and
  `RestoreInvoice` verbs POST the sub-resource, reading the path from the object's `Configuration` so a
  vendor change stays a metadata edit, and falling back to the documented path when the seed predates
  the key or the object is not cached at all — a cancel should not fail because discovery has not run.
  Both are idempotent, matching the endpoint. Note for consumers confirming a cancellation: BILL leaves
  `status` at `OPEN` and moves `archived` to true with `recordStatus` `INACTIVE`, so the check is
  `archived`, never `status`.

  **Validation failures now say what was wrong.** BILL reports them as a bare array of
  `{timestamp, severity, message}`, which reaches `typeof body === 'object'` but carries none of the
  keys `ExtractErrorMessage` looked for, so every 400 surfaced as `HTTP 400 on <verb>` with the reason
  discarded. Array bodies are joined on `message`.

  Verified against the BILL stage sandbox: customer and invoice create, read-back, archive (including a
  second archive returning 200), and a duplicate `invoiceNumber` correctly refused with 422.

## 0.3.1

### Patch Changes

- 06b2b4b: Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

  Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

  Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.

## 0.3.0

### Minor Changes

- 1433a9d: Ship Get/Create/Update Actions for Bill.com invoices.

  The connector could already write invoices — `invoices` declares `CreateAPIPath` and `UpdateAPIPath`, and
  `SupportsCreate`/`SupportsUpdate` are both true — but only through `IntegrationWriteRecord`, which means
  from code. Without Action metadata the write surface is not reachable by an agent or a flow, which is the
  gap this closes for the accounts-receivable use case.

  Actions are generated from the connector's own object model rather than hand-authored: each carries
  `DriverClass='IntegrationActionExecutor'` and a `{IntegrationName, ObjectName, Verb}` config triple, and
  that triple is the whole implementation. Params are derived from the invoice field set, so an agent sees
  the real fields.

  **Only three of the twenty-one generated actions are shipped**, because the generator emits a uniform
  verb cross-product that does not match this connector's capability:

  - `ActionMetadataGenerator` gates Create/Update/Delete/Upsert on a single `SupportsWrite` boolean, so it
    emitted Delete actions for all three objects even though the connector declares
    `SupportsDelete(): false`, and an Update for `receivable-payments`, which has no `UpdateAPIPath`.
  - `Search` and `List` are emitted unconditionally, with no check that the connector implements them.

  Those would have appeared to an agent as available operations that can only ever return `NOT_SUPPORTED`.
  The generator defect is left for a separate fix — it affects every connector, and Business Central's
  four-action anomaly is the same code misbehaving on an unseeded cache.

  `customers` and `receivable-payments` actions are deliberately not included; only the invoice path was
  asked for and only it is verified against the declared surface.

## 0.2.1

### Patch Changes

- 6ee916d: Relicense to the Business Source License 1.1.

  Metadata and documentation only: the `license` field moves to `BUSL-1.1` and the
  repo gains a LICENSE file. No runtime behaviour, API surface, or dependency
  changes. The bump exists so the new licence metadata reaches npm, since the
  registry shows the licence of the latest published version.

## 0.2.0

### Minor Changes

- 0567edc: Add the Bill.com (BILL) v3 Connect API connector — accounts receivable.

  Covers customers, invoices, and receivable-payments: create and cancel invoices (cancel is
  `POST /v3/invoices/{id}/archive`, not a delete or status change), and detect received payments
  via incremental sync on `updatedTime`.

  Vendor characteristics handled explicitly:

  - Session auth with a 35-minute sliding idle expiry and no refresh mechanism — the session is
    cached and reused, with proactive re-login and a single re-login-and-replay on 401. Logins are
    capped at 200/hour, so acquiring one per request is not viable.
  - Concurrency capped at 3 per developer key per organization (`BDC_1322`).
  - Opaque-cursor pagination terminating on the absence of `nextPage`, not on an empty page.
  - The invoice customer reference differs between read and write: BILL returns a flat `customerId`
    string but requires a nested `customer` object (`{"id":"0cu…"}`) on create. The catalog declares
    both, since sending the read name fails every create with HTTP 400.

  The catalog and the Action object model are both generated from BILL's published OpenAPI by
  `scripts/extract-catalog.mjs`, so they cannot drift apart.

  Refunds are deliberately absent: v3 has no AR refund endpoint, `/v3/orders` does not exist, and
  negative invoices are unsupported.

  Verified against BILL's real API using a sandbox account (evidence tier 🟢 Live-vendor). Session
  login, all three read paths, the `updatedTime` incremental filter, cursor advance, invoice create,
  invoice archive and its idempotency, and the customers-`PATCH`/invoices-`PUT` asymmetry are all
  confirmed live. Creating a receivable payment is declared but unproven — charging a customer
  requires an authorized customer with a bank account, which a fresh sandbox cannot provide. No write
  has been executed against a production BILL organization.
