-- PheedLoop: the one writable object that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- EventAttendance -> WITHDRAW the write.
--    It is the event-scoped check-in ENVELOPE, not a record. All four declared fields are read-only
--    ARRAYS of attendee codes — checked_in / not_checked_in from GET /events/{eventCode}/attendance/,
--    attendees / errored_attendees from POST /events/{eventCode}/checkin/ — so a row is a whole
--    event's aggregate, with no per-record identity to key on. Turning it into one row per attendee
--    is a connector change, not a key stamp, so it is deliberately out of scope here.
--
--    Per-attendee check-in is unaffected and already modelled: the sibling SessionRegistration
--    (/events/{eventCode}/sessions/{sessionCode}/attendance/) is keyed on the attendee `code` and
--    keeps full create/update/delete. Reads on EventAttendance are unaffected.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202606271400 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).

UPDATE [__mj].IntegrationObject
SET SupportsWrite  = 0,
    SupportsCreate = 0,
    SupportsDelete = 0,
    Description    = N'PheedLoop Event Attendance (event-scoped check-in/check-out state). GET .../attendance/ returns checked_in / not_checked_in attendee-code lists; POST .../checkin/ checks attendees in; DELETE .../checkout/ checks them out. Source: Postman collection v3.... Event-scoped aggregate, not a record: all four declared fields are read-only arrays of attendee codes (the check-in/check-out envelope), so there is no per-record identity to key on. Per-attendee check-in remains available on SessionRegistration, which is keyed on the attendee code. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves fail. Reads are unaffected.'
WHERE ID = '56517D7D-E5AE-42BF-9EF5-05740515A0A1';
