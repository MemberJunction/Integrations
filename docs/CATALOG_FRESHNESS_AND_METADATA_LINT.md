# Catalog freshness (A9 / A9b) & metadata-field lint (A11)

Three CI guards + their standing tech-debt, all against one failure mode: **a declaration nobody
can check**, so a green run confirms a fiction. Each guards a different way that happens —

| | The declaration | What goes unchecked |
|---|---|---|
| **A9** | a connector version on `next` | the tag an install actually resolves has moved past it |
| **A9b** | a declared object catalog | *what vendor artifact it was derived from, and when* |
| **A11** | a metadata `fields.*` key | `SetLocal` drops it on push, so it reaches no tenant |

---

## A9 — Catalog freshness (branch-vs-tag)

### How connectors resolve (verified in this repo)

Installs/upgrades resolve **by git tag**, not by the `next` branch:

- `connectors-catalog.json` is the browse/install source. Its `installTag` field is literally
  `` `${category}-${connectorDir}@${pkg.version}` `` (see `scripts/build-connectors-catalog.mjs`) —
  a `<Category>-<Connector>@x.y.z` git-tag reference. The `version` field is likewise **baked from
  package.json at catalog-build time** into the committed artifact.
- **No script in this repo reads a connector version from the live `next` branch at install time.**
  `grep -rn 'next' scripts/` turns up only diff-base refs (`origin/next` for changeset/metadata
  gates), never a resolution path. So the consumer resolves the catalog's baked `installTag` (a tag).

**Consequence:** `next`-vs-tag drift is **repo hygiene** (stale conservative defaults authored on
`next`), not per-install correctness — *as long as* nothing resolves live from `next`. Keep it that
way; if a future path ever reads `next` live, the merge-back below becomes load-bearing for
correctness.

### The drift

Releases are cut + tagged on `main`, but the version-bump commit is often never merged back to
`next`, so `next` lags the newest tag. The old `build-connectors-catalog.mjs --check` only compares
**within** `next` (catalog vs package.json) and is blind to this.

### The guard

- `scripts/check-catalog-freshness.mjs` — compares each connector's package.json version to its
  highest semver tag; fails on any lag. Modes: `--report` (never fail), `--public-only`, `--json`.
- `.github/workflows/catalog-freshness.yml` — daily `schedule` + `workflow_dispatch`. Deliberately a
  **branch-state** check, not a per-PR gate (the recurrence never arrives via a `next` PR, and
  per-PR gating would block unrelated PRs on pre-existing drift).

### Status: the merge-back sweep landed

**Updated 2026-08-26.** The 15-connector worklist this section used to carry is **done** — every
connector on it now matches its newest tag. Current state
(`node scripts/check-catalog-freshness.mjs --json`):

| Connector | next | newest tag |
|---|---|---|
| LMS/Elevate | 0.1.0 | 0.2.0 |

**1 of 56** lagging (1 of 49 public; the 7 private/held connectors are all current). The daily
workflow is therefore still RED, but for a *different and much smaller* reason than the text here
previously claimed — do not read a red run as evidence that the old sweep is outstanding.

`LMS/Elevate` is the one live case, and the original caution still applies to it: a version-only
bump-back on `next` trips `scripts/require-changeset.mjs` (the target version is already on npm ⇒
"already-published connector changed with no covering changeset"), and adding a changeset would
**double-bump** on the next `next → main` release. The correct reconciliation is a `main → next`
merge-back of that release's version commit (or a `git checkout <tag> -- LMS/Elevate` of just the
version/changelog files, committed without a new changeset), verified against the changeset/publish
flow.

## A9b — Catalog-freshness pin (declared-against)

### The bug class

A9 above compares a **package version to a git tag**. It is silent on whether a connector's
declared object catalog still matches the vendor API it was derived from — a connector can be
perfectly tag-current and declared against a two-year-old spec.

The catalog is derived from a vendor artifact: an OpenAPI doc, a WSDL, a plugin's PHP source, a
support-site article. That artifact moves; the catalog does not. With no record of **which**
artifact was read and **when**, a stale catalog is indistinguishable from a current one — a
missing object could mean the connector is wrong or the vendor moved after we looked, and nothing
says which. The declaration reads as settled fact because the gap was never written down.

### The guard

- `scripts/lint-catalog-freshness-pin.mjs` — every connector's
  `metadata/integration/*.integration.json` must carry `fields.Configuration.DeclaredAgainst`
  containing, at any depth, **at least one source URL** (what was read) and **at least one ISO
  date** (when). Modes: `--report` (never fail), `--json`.
- Wired into `pr.yml` and `release.yml` as **Catalog freshness pin declared**.

The bar is deliberately low — URL + date, nothing more. The richer pins in the tree are what make
a pin genuinely useful, and they are **documented best practice, not enforced**; a bar high enough
to be ignored guards nothing. The worked examples:

| | `Platform/WordPress` | `AMS/NetForum` |
|---|---|---|
| artifact hash | zip `sha256` for WP + Woo | **absent** — recorded as a gap |
| vendor version | `wp 7.1` / `woocommerce 11.0.1` | **absent** — recorded as a gap |
| source vs edit date | — | `accessedAt` + `catalogLastEditedAt` |

netFORUM is the instructive one: its block records what it *cannot* prove as explicitly as what it
can. An unrecorded gap reads as a settled fact, so "no sha256 was captured" is itself worth
declaring.

### Standing debt: the 53 grandfathered connectors

Only **3 of 56** connectors pinned at the time the guard landed (`AMS/NetForum`,
`Platform/WordPress`, `LMS/Elevate`). The other 53 are listed in `GRANDFATHERED` in the linter, so
it is green on day one and a **new connector must pin from day one**.

Backfilling those 53 is *not* scheduled as a campaign: each needs a real source fetch, cannot be
inferred from the repo, and a fabricated pin is worse than no pin. The intended path is
opportunistic — a grandfathered connector gains its pin whenever someone next touches that
connector's metadata for other reasons.

The exemption is checked in **both directions**: once a grandfathered connector gains a valid pin,
the linter fails until its entry is deleted. The debt list can only shrink, and can never quietly
rot into a list of connectors that are actually fine.

---

## A11 — Metadata-field lint (declared ≠ deployed)

### The bug class

A connector's `metadata/integration/*.integration.json` record `fields.*` are pushed to the `__mj`
catalog by `mj sync push`, but **`BaseEntity.SetLocal` silently drops any key that is not a real
entity column**. An authored-but-inert field (e.g. `Integration.APIBaseURL` — not a column; the real
one is `NavigationBaseURL`) looks declared but reaches no tenant and no test can see the drop.

### The guard

- `scripts/lint-metadata-fields.mjs` — every `fields.*` key on an Integration /
  IntegrationObject / IntegrationObjectField record must be one of:
  1. a **real entity column** — proven by the `spCreate*/spUpdate*` `@Params` in generated
     migrations (auto-harvested), seeded with a hardcoded floor of the sproc signatures;
  2. a **framework-ideal** field — the documented "ideal-but-not-deployed" set that SetLocal drops on
     purpose (`Source`, `IsForeignKey`, `IsMutable`, `IsAppendOnly`, `IncludeInActionGeneration`,
     `SupportsRead`, `ParentObjectName`, `ParentObjectIDFieldName`, `HierarchyPath` — see
     `scripts/build-seed-migrations.mjs`);
  3. a **grandfathered** debt entry (below).
  The free-form `Configuration` JSON blob is **out of scope** — it is open-ended per-connector
  documentation (300+ distinct keys, `*Note`/`*Gap`/`*Rationale` conventions), not entity columns.
- Wired into `pr.yml` and `release.yml` as **Metadata fields on allowlist**.

### Deferred: universalPK (wire-or-remove + shape-standardize)

`universalPK` lives inside the free-form `Configuration` blob and **is read by no code in this repo**
(`grep -rn 'universalPK\|UniversalPKConvention'` over `*.ts/*.js` is empty). The engine consumes a
differently-named `UniversalPKConvention` opt (cross-repo — `IntegrationConnectorCreationPipeline.js`).
Whether the metadata `universalPK` feeds that opt is **unconfirmed from this repo**, so wire-or-remove
is **deferred**. The lint emits a non-gating shape audit (`--audit`) as the sweep inventory; today:

- **object** (integration-level map, ORCID-style): 27
- **string (per-object)** (`"universalPK": "Id"`, NimbleAMS/Salesforce-style): 31
- **gap-note** (`universalPKGap`, PropFuel-style): 1

Resolution when confirmed: pick the per-object **object** form as canonical, migrate the string form,
and either map it into `UniversalPKConvention` (make it LIVE) or delete it (it is INERT today).

### Deferred: grandfathered inert field `APIBaseURL`

Present on `AMS/WildApricot` and `Events/PheedLoop` Integration rows; **not** a `spCreateIntegration`
column, so SetLocal drops it (in the generated migration it only survives inside the Configuration
JSON blob, never as a column). Not removed here because editing the metadata trips
`require-metadata-migration.mjs` (metadata change ⇒ a new `V*.sql` is demanded) with no real delta to
emit. Resolve via the metadata sweep: remove the key (or rename to `NavigationBaseURL` if intended),
regenerate the connector's migration, then delete it from `GRANDFATHERED` in the lint.
