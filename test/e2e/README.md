# Credential-free hybrid-e2e harness

This directory holds the harness that produces the **22-cell behavioral matrix** cited in connector
PRs, plus the mock-vendor fixtures for the connectors that have been run through it. It exists so a
connector's behavioral evidence is **reproducible by a reviewer** rather than asserted by its author.

It runs with **no vendor credential**. The connector is driven against a mock vendor that replays
fixtures generated from the vendor's own published API spec, so the harness measures real behavior
(rows landed, ordering, idempotency, delta, pagination, rate-limit, retry, write shape) without
touching a live tenant.

## Why this is here and not somewhere shared

The harness was developed alongside the connectors and was, until now, **untracked** — which meant
the evidence quoted in connector PRs could not be re-run by anyone else. That is a defect in the
proof, independent of whether any individual connector works. Committing it here fixes that.

## What a green run does and does not prove

**Does:** the connector's read path enumerates every declared object and lands rows; incremental
narrowing works; a second pass writes nothing; deltas including a delete-tombstone apply; pagination
follows a cursor and terminates; the DAG applies parents before children; a 429 storm is backed off
and recovered; transient errors retry with per-record dead-lettering; write requests are shaped
correctly at the transport boundary.

**Does not:** prove anything against the real vendor API. There is no credential in this loop. Write
round-trips are asserted as *requests the connector would send*, never as records observed to land,
and true rate-limit behavior can only be characterized against the live vendor. A green here means
**"behaviorally sound and contract-conformant,"** not "field-proven." Treat the two differently.

## Anti-vacuous rules the harness enforces

A green must mean *observed to work*, never *ran without error*. These are automatic failures:

- any per-object rowcount of `0` where the fixture supplies data (in mock mode the fixture controls
  all data, so a 0-row object is a **fixture gap**, never "legitimately empty");
- `delta ok` on zero succeeded records;
- an outcome assertion left unmeasured;
- a green that reused rows from a prior run (every count carries this-run provenance);
- a single-object sync standing in for the catalog — the object list is always the **full declared
  catalog** (`__ALL__`), never a subset, since a narrowed list cannot support an all-objects claim.

Three fixes were made to this harness while proving the Reply connector, each of which had been
letting a **vacuous** green through. They are recorded here because they apply to every connector,
not just Reply:

1. **Write-only carve-out mis-fired.** Coverage exempted any object whose `APIPath` byte-equals its
   own Create path — true of *every* ordinary REST collection (`GET/POST /v3/sequences`). That shrank
   the syncable denominator and handed false transitive exemptions to children. Rows-landed evidence
   now overrides the static heuristic.
2. **That override could not rescue a 0-row object** — exactly where a real gap hides. A
   `SECOND_LAYER_EMPTY` warning is emitted only when the engine actually enumerated an object *and*
   its parents synced rows, which is positive proof the object is reachable, so that warning now
   **vetoes** the exemption outright.
3. **`dag.topological-layering` was vacuous for every PascalCase connector.** It only recognized a
   child whose name matched `/assoc|_/`, so it reported "no parent→child edge, layering trivially
   satisfied" over a taxonomy in which `dag.full-hierarchy` had just found 19 FK edges. It is now
   naming-agnostic, and reports `assertionMeaningful: false` when every `Priority` is equal — because
   `parentPrio <= childPrio` is then unfalsifiable and a pass proves nothing about fetch order.

## Running the Reply matrix

Prerequisites: a SQL Server with an MJ database at a core `__mj` baseline, the Reply catalog seeded
into it (`Marketing/Reply/migrations/`), a `CompanyIntegration` row for Reply, and an MJAPI instance
serving that database.

```bash
E2E_DB_PASSWORD='<sql password>' \
MJ_API_KEY='<mj system key>' \
E2E_COMPANY_ID='<CompanyIntegration ID>' \
E2E_DB_PORT=1505 E2E_DB_NAME=MJ_REPLY_E2E \
E2E_GRAPHQL_URL=http://localhost:4017/ \
node test/e2e/run-reply-mock.mjs
```

Takes roughly 12–14 minutes. Exits non-zero if any applicable cell fails. **No credential of any
kind belongs in a file in this directory** — every secret is read from the environment.

Expected shape of a passing run:

```
topOk: true
forward: objects>0 rows: 51 / 51 | zero-row: 0
coverage.all-objects ok: true  syncableObjects: 51, coveredWithRows: 51,
                               zeroRowReal: 0, zeroRowLegitEmpty: 0
```

The line that matters is the last one: every syncable object landed rows and **nothing was excused**.
A run reporting `zeroRowLegitEmpty > 0` in mock mode should be read as a fixture gap to fix, not as a
pass with a footnote.
