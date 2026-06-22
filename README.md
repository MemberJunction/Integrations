# MemberJunction Integrations

Vendor integration **connectors for MemberJunction, published as installable Open Apps.** Each connector
lives under `<Category>/<Connector>/` and installs on demand:

```bash
mj app install https://github.com/MemberJunction/Integrations/CRM/HubSpot
```

Nothing is seeded into a MemberJunction database until you install the connector you want — which is the
whole point: the core MJ install no longer carries the full IntegrationObject/IntegrationObjectField
catalog for every vendor.

## How it works

- **One shared npm package** — [`@memberjunction/integration-connectors`](packages/integration-connectors)
  holds every connector's code (the `@RegisterClass(BaseIntegrationConnector, …)` classes). Every connector
  Open App references this same package; only the seeded **metadata** differs per connector.
- **Connector-profile Open Apps** — each `<Category>/<Connector>/mj-app.json` is a *connector profile*: it
  declares **no database schema and no migrations**, only `metadata.processOnInstall: true`. Installing it
  runs `npm install @memberjunction/integration-connectors` + a scoped `mj sync push` of the connector's
  `metadata/` (its `MJ: Integrations` row + `MJ: Integration Objects` / `…Object Fields` + `MJ: Actions`)
  and wires the package into the server so the MJ ClassFactory can resolve the connector at runtime.
- **The framework stays in core MJ** — `@memberjunction/integration-engine` (+ `-engine-base`,
  `-schema-builder`, `-pk-classifier`, `-actions`, the Integration/IO/IOF tables, runtime discovery,
  credential types, and the bizapps Action-Category tree) all remain in the MemberJunction monorepo and are
  consumed from npm. This repo ships **connectors only**.

The **three-way invariant** is preserved unchanged for every connector:
`Integration.ClassName` (metadata) == the `@RegisterClass` driver string (code) == the connector's
`IntegrationName` getter. `scripts/validate-invariants.mjs` enforces it (plus full `mj-app.json` Zod
validation) on every PR.

## Repository layout

```
Integrations/
├── packages/integration-connectors/   # @memberjunction/integration-connectors — all connector classes
│   └── src/                            # <Vendor>Connector.ts + __tests__ + registerConnectors() shim
├── CRM/        HubSpot, Salesforce, NeonCRM, DynamicsDataverse, Blackbaud
├── AMS/        Aptify, iMIS, NimbleAMS, Novi, NetForum, Fonteva, GrowthZone, Rhythm, MemberSuite, Wicket, WildApricot, YourMembership
├── LMS/        PathLMS, Reach360
├── Marketing/  Mailchimp, ConstantContact, MagnetMail, Rasa, PropFuel
├── Finance/    QuickBooks, SageIntacct, NetSuite
├── Events/     Cvent, PheedLoop, OpenWater
├── Platform/   SharePoint, ORCID, Hivebrite, MJtoMJ
├── scripts/    scaffold-openapps.mjs, validate-invariants.mjs
└── .github/workflows/  pr.yml, release.yml
```

Each connector directory is **both** an installable Open App (its `mj-app.json` + `metadata/`, fetched over
GitHub at install time) and — only for `packages/integration-connectors` — an npm workspace member. The
`mj-app.json` + `metadata/` siblings are invisible to npm/turbo.

## Versioning & install

- The shared package is versioned with **changesets**; releases cut a repo-wide `vX.Y.Z` git tag.
- `mj app install …/CRM/HubSpot --version 1.2.0` reads `CRM/HubSpot/mj-app.json` at that tag (the in-repo
  subpath selects the app; the tag selects the version).
- Connectors declare `mjVersionRange` (`>=5.43.0 <6.0.0`) and depend on the published MJ framework packages
  as **peer dependencies**, so a connector binds to the host app's framework copy (no duplicate
  `integration-engine`, which would split the `@RegisterClass` registry).

## Requirements

Requires a MemberJunction host running **≥ 5.43.0** — the release that adds multi-app-per-repo subpath
installs and the connector-profile (`metadata.processOnInstall`) install mode to `@memberjunction/open-app-engine`.

## Development

```bash
npm install
npm run build            # turbo build of the shared package
npm test                 # vitest (credential-free unit tests; live e2e self-skips without a DB)
npm run lint:invariants  # connector Open App floor-check
```

To (re)generate the per-connector Open App directories from the MJ core metadata (one-time extraction /
refresh tool):

```bash
MJ_METADATA_DIR=/path/to/MJ/metadata npm run scaffold:openapps
```

## Notes

- `RelationalDBConnector` / `FileFeedConnector` are framework-generic primitives (no static vendor catalog),
  so they ship in the shared package but have no per-vendor Open App.
- Connector **Actions** `@lookup` the bizapps Action-Category tree and **credential types**, both of which
  remain core-seeded MJ metadata.
