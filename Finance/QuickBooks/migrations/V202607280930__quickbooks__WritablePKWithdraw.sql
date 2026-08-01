-- QuickBooks Online: the two writable objects that carry no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- Both objects reached that state honestly. The 2.0.0 reality probe (2026-07-26) measured the
-- declared PK 'Id' over a live page and found it ABSENT on every record:
--     ExchangeRate          Id populated 0/1000, absent 1000/1000
--     RecurringTransaction  Id populated 0/2,    absent 2/2
-- so the PK was demoted to content-hash identity, which is correct — QBO genuinely does not assign
-- an Id to either. That fixes the read side and leaves the write side declaring a capability the
-- object cannot deliver. This migration withdraws that claim. Reads are unaffected on both: the
-- content-hash (__mj_integration_ContentHash) remains the row identity for dedupe/upsert.
--
-- 1. ExchangeRate -> WITHDRAW write.
--    QBO identifies a rate by SourceCurrencyCode + TargetCurrencyCode + AsOfDate rather than a
--    server id, and the /query response carries all three. That triple is a plausible composite key
--    — but the probe measured population on 'Id' ONLY, so there is no evidence any of the three is
--    non-null in practice, and stamping IsPrimaryKey on an unmeasured field is the same defect in
--    the other direction (a declared key that is null at runtime keys nothing). The write is
--    withdrawn rather than guessed. Restoring it is one probe away: measure the three fields over a
--    page and, if populated, stamp them IsPrimaryKey and re-enable SupportsWrite/Create/Update.
--
-- 2. RecurringTransaction -> WITHDRAW write.
--    No key candidate exists to promote. The object is a WRAPPER whose real key is nested inside the
--    contained transaction (RecurringInfo + the embedded Invoice/Bill/…); it exposes no top-level
--    id, and it declares exactly two fields (Id, SyncToken) — so MJ has no columns to build a create
--    body from either. Modelling this write properly means flattening the contained transaction into
--    real fields, which is object authoring, not a key stamp.
--
-- DELTA migration, deliberately not a re-seed: the 2.0.0 catalog rows are written by
-- V202607280117__quickbooks__Metadata.sql, which stays untouched and applied — no existing UUID is
-- re-minted, no Flyway checksum breaks, no UQ collision. Both statements are idempotent (keyed by
-- the seeded row ID).

-- ── 1. ExchangeRate ──
UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    SupportsUpdate = 0,
    Description    = N'QuickBooks Online v3 ExchangeRate (namelist). Write withdrawn: the reality probe found the declared PK ''Id'' absent on 1000/1000 records, so the PK was demoted to content-hash identity and the object derives a KEYLESS entity — on Postgres every save then fails with `syntax error at or near ","` while fetch keeps succeeding, so the object would read green and persist nothing. QBO identifies a rate by SourceCurrencyCode + TargetCurrencyCode + AsOfDate rather than a server id, but the probe measured population on ''Id'' only, so promoting that triple to a composite key is unevidenced and is not done here. Restoring the write is a probe away: measure those three fields over a page, and if they are populated, stamp them IsPrimaryKey and re-enable. Reads are unaffected (content-hash identity, 1000 records, incremental on MetaData.LastUpdatedTime, both confirmed by probe).'
WHERE ID = 'B4A7088A-0070-43AD-81DB-B15A1372090B';

-- ── 2. RecurringTransaction ──
UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    SupportsUpdate = 0,
    Description    = N'QuickBooks Online v3 RecurringTransaction (transaction). Write withdrawn: the reality probe found the declared PK ''Id'' absent on 2/2 records, so the PK was demoted to content-hash identity and the object derives a KEYLESS entity — on Postgres every save then fails with `syntax error at or near ","` while fetch keeps succeeding. Unlike ExchangeRate there is no key candidate to promote: the object is a WRAPPER whose real key is nested inside the contained transaction (RecurringInfo + the embedded Invoice/Bill/…), it exposes no top-level id, and it declares only two fields (Id, SyncToken) — so MJ has no columns to build a create body from either. Modelling the write properly means flattening the contained transaction into real fields, which is object authoring, not a key stamp. Reads are unaffected (content-hash identity, 2 records).'
WHERE ID = 'BED26CA4-9CC5-4E18-B34A-51E14A087B81';
