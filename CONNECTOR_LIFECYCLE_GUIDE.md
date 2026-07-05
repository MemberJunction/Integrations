# Connector lifecycle — build → publish (current, 2026-06-27)

> **Discovery standard:** every describe-endpoint connector must union its declared catalog with a
> bounded data-sample by overriding its own `IntrospectSchema` (pure wiring of MJ's
> `DiscoverFieldsViaFetch` sampler + the shared pure `mergeDeclaredWithSampledFields` helper — no base
> class, no re-parenting, never touch `DiscoverFields`). See
> [docs/CONNECTOR_DISCOVERY_STANDARD.md](docs/CONNECTOR_DISCOVERY_STANDARD.md).

Two phases. **Build** (connector-builder-v2, in the MJ repo) produces the connector's code + metadata + tests.
**Publish** (this Integrations repo) turns that into an installable 1.0.0 Open App via the seed-migration pipeline
proven this session. The build half got the 3-mode arc; the publish half is brand new — together they make
"build a connector" mean "ship a connector a customer can `mj app install`."

---

## Phase A — BUILD (connector-builder-v2 / `/build-connector`)

Run in the **MJ-v2** worktree (branch `agentic/connector-builder-v2`). Invocation:

```
/build-connector <vendor> [--context <path-or-inline>] [--budget <tokens>] [--max-tier <T0..T8>]
```

It always runs **Step 0** first (non-skippable):
- **0a Context** — paste/point at vendor docs, OpenAPI/Postman, sample payloads, known quirks. Highest-priority
  source, but never the whole truth: the arc *independently* studies the vendor's full API surface and reconciles.
- **0c Mode** (deterministic classifier; you confirm, it never guesses):
  - **`new`** — no existing metadata → births `1.0.0`, full Plan→Review→Execute. **← Eventbrite.**
  - **`redo`** — exists but fails a structural floor gate OR you want a breaking change → **major** `N.0.0`,
    full re-extract + re-test + deprecation/reseed-delete of the prior objects. **← WildApricot (recreate).**
  - **`additive`** — exists + floor-clean + the vendor's universe grew (or a code-only fix) → **minor/patch**,
    scoped delta, unchanged objects' green stands. (The common "vendor added 3 fields" case.)
- **0b Credential** — **[A]** you broker a test credential → read-only live (T8) *on top of* the full non-live
  suite; **[B]** no credential → full non-live suite (spec/mock-server/probe/bijection). Credential is held by a
  separate OS user (the broker); the agent never sees its bytes. Live is **read-only only**, every connector.

**Output**: the connector class + `metadata/integrations/<vendor>/.<vendor>.integration.json` + tests, vetted
through the verification ladder (T0–T8) and an adversarial reviewer.

### Credential-free is real coverage (validated this session)
The 4 live-proven connectors (GZ/PL/SP/PropFuel) confirmed credential-free *predicts* live: every mock-green
cell held live, the RealityProbe even pre-empted OpenWater's dead host. So **[B] is a legitimate ship path** —
state the ceiling (`format-verified-no-creds`) honestly; don't imply live proof it didn't have.

---

## Phase B — PUBLISH (this repo) — the seed-migration pipeline

A connector installs by running its **seed migration** (`mj app install` → Skyway Step 8: DDL + metadata DML).
The migration is **pure `spCreate`** calls into the core `__mj` integration catalog — **no codegen, nothing
appended** (verified against MJ's own metadata-sync migrations). Generate it per connector against a fresh 5.43 DB:

```bash
# one-time: a 5.43 generation DB (MJ_CONN_GEN) with __mj + the integration spCreate sprocs
# then, per connector (or all in scope):
DB_HOST=localhost DB_PORT=1444 DB_DATABASE=MJ_CONN_GEN DB_USERNAME=sa DB_PASSWORD=… \
  node scripts/build-seed-migrations.mjs <Category>/<Connector>     # e.g. Events/Eventbrite
```

The driver, per connector: **reset the `__mj` catalog** (IntegrationObject.Name is globally unique — each
connector needs a clean slate) → **`mj sync push@5.43.0`** (seeds + emits the SQL, writes `primaryKey`/`sync`
back into the metadata for deterministic re-runs) → **`wrap-migration.mjs`** (→ `V<12-digit>__<slug>__Metadata.sql`)
→ **`build-pg-migrations.mjs`** (the `.pg.sql` variant).

### Install-test (the real bar — "the open-app func can handle it")
```bash
# fresh 5.43 DB + the app schema, then run the seed via the SAME Skyway path mj app install uses:
mj migrate --schema mj_connector_<slug> --dir <Category>/<Connector>/migrations
# verify: the connector's Integration + objects + fields land in __mj, FK @lookups resolve.
```

### Then version + publish (the 20-scope flow)
- Versions are `1.0.0` (set at package-split); `sync-manifest-versions.mjs` keeps `mj-app.json` in lockstep.
- Create a **changeset for the connector** → `changeset publish` (per-connector npm publish) → `tag-apps.mjs`
  tags `Category-Connector@1.0.0` (what `mj app install …/<Category>/<Connector> --version` resolves).
- Scope control: `scripts/connector-publish-scope.json` — only `publish[]` ships; `hold[]` stays on `next`.

---

## The deploy-blocker preflight (every connector, learned this session — check ALL)
1. **`Description` ≤ 255** — the `__mj.IntegrationObject(Field).Description` column is `NVARCHAR(255)`; longer
   rolls back the push/install. (17 of the first 20 violated it.)
2. **`push.autoCreateMissingRecords=true`** in the connector's `metadata/.mj-sync.json` — or re-generation fails
   "Record not found" after the catalog reset (parent Integration can't be recreated by its fixed PK).
3. **FK `@lookup` qualifier** = `&IntegrationID=@parent:IntegrationID` (never `@parent:ID`) — else generic names
   (`record`, `Membership`) mis-resolve across connectors in a multi-connector install.
4. **Non-column metadata noise** (`IsForeignKey`, `Source`, `IsMutable`, …) — silently dropped at push; strict
   `--ci` validation rejects them, so generation uses `--no-validate` (real `@lookup` resolution still runs).
5. **No duplicate IOF name within an IO**, every IO carries `IntegrationID:@parent:ID`, valid `PaginationType` enum.

---

## Day plan — TWO connectors per day (build + publish each, same day)

The cadence is two/day because each connector is now: Phase A build (hours, mostly unattended agent work) +
Phase B publish (minutes). Run the two builds in parallel where the docs are good; the publish pipeline is serial
but fast. Each connector ends the day **built, seed-migrated, install-tested, and published** — not half-done.

**Day 0 (now)** — finish the 20 seed migrations (running) → validate → install-test the giants → review → publish 1.0.0.
**Day 1 — WildApricot (`redo`) + Eventbrite (`new`)**:
  - WildApricot: `/build-connector wildapricot` → confirm `redo` → re-extract/re-test/reseed-delete → Phase B → next major.
  - Eventbrite: `/build-connector eventbrite --context <Eventbrite OpenAPI>` → `1.0.0` → Phase B → add `Events/Eventbrite` to `publish[]`.
**Day 2 — two more** (you name them, or two of the held 14 that are floor-clean → fast `additive` re-prove).
**Day 3+** — two/day through the backlog; live-verify any whose credentials arrive (lifts the ceiling to verified-live).

**Throughput guardrail:** two/day holds when the vendor has real machine-readable docs (OpenAPI/GraphQL SDL) and
`new`/`additive` mode. A `redo` on a giant catalog (1000+ objects) or a credential-gated live-verify can stretch one
of the two — sequence the *cheap* one second so a slow build never blocks the day's ship.
