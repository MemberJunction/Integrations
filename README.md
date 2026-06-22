# MemberJunction Integrations

Vendor integration **connectors for MemberJunction, each published as its own independent Open App**.
Every connector lives under `<Category>/<Connector>/` and installs on demand:

```bash
mj app install https://github.com/MemberJunction/Integrations/CRM/HubSpot
```

Nothing is seeded into a MemberJunction database until you install the connector you want, and
**installing one connector pulls only that connector's package** — connectors are fully decoupled.

## How it works

- **One package per connector.** Each `<Category>/<Connector>/` directory is a self-contained npm
  package (`@memberjunction/connector-<name>`) *and* an Open App: its own `package.json` + `src/`
  (the `@RegisterClass(BaseIntegrationConnector, …)` class + tests) + `mj-app.json` + `metadata/`.
  Installing HubSpot installs only `@memberjunction/connector-hubspot` — never any other connector.
- **Connector-profile Open Apps.** Each `mj-app.json` declares **no database schema and no migrations**,
  only `metadata.processOnInstall: true`. Installing it runs `npm install` of that one connector
  package + a scoped `mj sync push` of the connector's `metadata/` (its `MJ: Integrations` row +
  `MJ: Integration Objects` / `…Object Fields` + `MJ: Actions`), and wires the package into the server
  so the MJ ClassFactory resolves the connector at runtime.
- **The framework stays in core MJ.** `@memberjunction/integration-engine` (+ `-engine-base`,
  `-schema-builder`, `-pk-classifier`, `-actions`, the Integration/IO/IOF tables, runtime discovery,
  credential types, the bizapps Action-Category tree) all remain in the MemberJunction monorepo and
  are consumed as **peer dependencies**, so a connector binds to the host app's framework copy (no
  duplicate `integration-engine`, which would split the `@RegisterClass` registry).

The **three-way invariant** holds per connector: `Integration.ClassName` (metadata) == the
`@RegisterClass` driver (code) == the connector's `IntegrationName` getter; plus
`packages.server[0].name` == the sibling `package.json` name == the Integration's `ImportPath`.
`scripts/validate-invariants.mjs` enforces all of it (+ full `mj-app.json` Zod validation) on every PR.

## Repository layout

```
Integrations/
├── CRM/        HubSpot, Salesforce, NeonCRM, DynamicsDataverse, Blackbaud
├── AMS/        Aptify, iMIS, NimbleAMS, Novi, NetForum, Fonteva, GrowthZone, Rhythm, MemberSuite, Wicket, WildApricot, YourMembership
├── LMS/        PathLMS, Reach360
├── Marketing/  Mailchimp, ConstantContact, MagnetMail, Rasa, PropFuel
├── Finance/    QuickBooks, SageIntacct, NetSuite
├── Events/     Cvent, PheedLoop, OpenWater
├── Platform/   SharePoint, ORCID, Hivebrite, MJtoMJ, RelationalDB*, FileFeed*
└── scripts/    validate-invariants.mjs, scaffold-openapps.mjs, split-into-packages.mjs

  <Category>/<Connector>/
  ├── package.json          @memberjunction/connector-<name>  (framework as peerDependencies)
  ├── tsconfig.json  vitest.config.ts
  ├── src/<Class>.ts  src/index.ts (re-export + registerConnector shim)  src/__tests__/
  ├── mj-app.json           connector profile → references THIS package
  └── metadata/             integration/ (curated IO/IOF) + actions/
```

`*` `RelationalDB` / `FileFeed` are framework-generic primitives with no vendor catalog, so they are
code-only packages (no `mj-app.json`). Workspaces glob: `["*/*"]`.

A connector may depend on another (e.g. Fonteva extends Salesforce) — that's a normal package
dependency (`@memberjunction/connector-salesforce`), declared in its `package.json`.

## Versioning & install

- Each connector package is versioned **independently** with **changesets**; releases publish only the
  changed packages and tag the repo.
- `mj app install …/CRM/HubSpot --version X.Y.Z` reads `CRM/HubSpot/mj-app.json` at that ref (the
  in-repo subpath selects the app; the tag selects the version).
- Connectors declare `mjVersionRange` (`>=5.43.0 <6.0.0`) and depend on the published MJ framework
  packages as peer dependencies.

## Requirements

Requires a MemberJunction host **≥ 5.43.0** — the release that adds multi-app-per-repo subpath installs
and the connector-profile (`metadata.processOnInstall`) install mode to `@memberjunction/open-app-engine`.

## Development

```bash
npm install
npm run build            # turbo build of every connector package
npm test                 # vitest (credential-free unit tests)
npm run lint:invariants  # connector Open App floor-check
```

`scripts/scaffold-openapps.mjs` (generate Open App dirs from MJ core metadata) and
`scripts/split-into-packages.mjs` (the one-time split from a single shared package into per-connector
packages) are the extraction tools used to bring this repo up.

## Notes

Connector **Actions** `@lookup` the bizapps Action-Category tree and **credential types**, both of which
remain core-seeded MJ metadata.
