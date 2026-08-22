---
'@memberjunction/connector-openwater': patch
---

The judge pair: a person-grain Judge object, and JudgeAssignment regains its pair grain.

- **`alternativeAccessPaths`** (new, general): an object may declare additional FULL walks —
  complete AccessPath objects, not just alternative entry paths — when its records live behind
  more than one door. The walks are unioned and deduplicated by primary key.
- **`Judge`** (new object, first union user): the API has no `/v2/Judges` list endpoint. Judges
  assigned to rounds come from the `AssignedToRound` walk; judges/managers on judge teams come
  embedded in `/v2/JudgeTeams` rows (`judges[]` / `managers[]`, identical JudgeInfo shape). A
  team-only judge never appears in the round walk, so neither source alone is the population.
- **`JudgeAssignment` PK widened to (userId, roundId)**: with userId alone, a judge assigned to
  several rounds collapsed to one row per person — the object silently held distinct judges
  instead of assignments. The always-injected roundId walk tag joins the key, via delta
  migration `V202608212210` (SQL Server + Postgres) handling both the promoted-field and
  fresh-tenant populations per the V202608050910 precedent. Installed tenants should expect
  re-keyed rows on the next sync; rows keyed under the old person-grain ExternalID are stale
  and can be cleaned after the refill.
