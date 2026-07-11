-- ClassName modernization (PG twin) — see the SQL Server migration of the
-- same version for rationale. Idempotent by WHERE.
SET search_path TO __mj, public;
UPDATE __mj."Integration"
SET "ClassName" = '@memberjunction/connector-reach360'
WHERE "Name" = 'Reach360' AND "ClassName" = 'Reach360Connector';
