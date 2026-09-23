---
'@memberjunction/connector-openwater': patch
---

Detail-only data can now arrive, and winner assignments are at the grain the client counts.

**Three objects had fields only a per-record GET returns, and none of it could arrive.** The swagger (read
2026-09-22) shows `/v2/Evaluations/{id}` carrying computed and rank scores plus the inline score, general
scoring answer and judge team arrays; `/v2/Sessions/{id}` carrying typeId, chairs, items and field values;
`/v2/Users/{id}` carrying the four role flags, profile field values and sub-account ids. The scores and
answers are the content of an evaluation. No new extraction mode was needed: the existing `detail-object`
and `detail-embedded` walks already fetch each door row's own detail, so the per-record GET is declared in
metadata. Eleven new objects: `EvaluationDetail` and three children, `SessionDetail` and three children,
`UserDetail` and two children. The judge rosters were audited too and are not affected (same item model,
different scoping).

**Winner assignments were declared at the round grain only.** `ApplicationWinnerType` is the round-level
menu of available types from `/v2/Programs`. The client's 89 counts per-application awards, which live in
`/v2/Applications/{id} -> roundSubmissions[].winnerTypes[]` as an array of type names. The 1.3.6 change
said so in its own body; #364 then skipped that array as a duplicate. It is not. New object
`ApplicationWinnerAssignment`, keyed (applicationId, roundId, name).

**Two small additions to the detail-embedded walk make the children keyable.** `AccessPath.segmentTags`
copies an intermediate node's field (the round submission's roundId) onto every element beneath it, never
overwriting a vendor value; `AccessPath.scalarLeafKey` keeps scalar leaves, which the walker used to drop
silently (every string in `winnerTypes[]`). With neither declared the walk behaves exactly as before. The
four #364 children (`ApplicationJudgeScorecard`, `ApplicationReceivedRecommendation`,
`ApplicationPendingRecommendation`, `ApplicationScoringQuestionScore`) gain `roundId` and their element
fields, declare composite keys, and leave the read-only PK baseline.

Every key comes from the swagger's element schemas, so nothing relies on soft-PK inference. Cost is one GET
per door row per detail walk, shared across siblings by the per-batch detail cache and bounded by #364's
concurrent slices. One delta migration pair (guarded INSERTs and UPDATEs, `LOWER(Name)` lookups).
