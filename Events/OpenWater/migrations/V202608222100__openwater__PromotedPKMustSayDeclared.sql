-- A field promoted to PRIMARY KEY by a delta migration must also be relabelled Declared.
--
-- V202608212210 completed JudgeAssignment's key into the (userId, roundId) pair, and on tenants
-- where `roundId` already existed it did that through an UPDATE rather than the INSERT. The UPDATE
-- set IsPrimaryKey/IsRequired/AllowsNull but left MetadataSource alone — so on those tenants
-- roundId became a PRIMARY KEY still labelled 'Discovered'.
--
-- The engine's overlay (decidePKPromotion) then does exactly what it is designed to do: an object
-- that has a declared PK cannot have a *Discovered* field in its key, so the next schema refresh
-- demotes it. Observed on a live tenant: the catalog went from `declared=roundId,userId` back to
-- `declared=userId`, which is the person-grain collapse V202608212210 existed to fix — a judge
-- assigned to several rounds folds to one row per person. The self-heal was right; the row was
-- mislabelled.
--
-- Matched by object + field name, not by ID: the row this has to repair is the pre-existing
-- promoted one, whose ID differs per tenant. Idempotent, and a no-op on tenants that took the
-- INSERT path (already 'Declared'). Re-asserts IsPrimaryKey because a refresh may already have
-- demoted it.

-- Written as a subquery rather than UPDATE ... FROM ... JOIN so the same statement is valid in
-- both dialects: the T-SQL update-through-alias form does not survive conversion to Postgres,
-- where the update target may not also appear in FROM.

UPDATE [__mj].IntegrationObjectField
SET IsPrimaryKey = 1,
    MetadataSource = N'Declared'
WHERE Name = N'roundId'
  AND (IsPrimaryKey = 0 OR MetadataSource <> N'Declared')
  AND IntegrationObjectID IN (
      SELECT o.ID
      FROM [__mj].IntegrationObject o
      JOIN [__mj].Integration i ON i.ID = o.IntegrationID
      WHERE i.Name = 'openwater' AND o.Name = N'JudgeAssignment');
