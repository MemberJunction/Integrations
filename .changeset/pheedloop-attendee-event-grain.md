---
'@memberjunction/connector-pheedloop': patch
---

PheedLoop: Attendees is one row per attendee PER EVENT, and its key now says so.

Attendees is `Scope: event` with APIPath `/events/{eventCode}/attendees/`, so it is fetched once per
event. An attendee who attended more than one event comes back once per event with the same `code`.
The key was `code` alone, and `code` was also marked unique, so those rows collapsed into one.

Measured on the same PheedLoop account across two workspaces: 370 attendee records fetched over 5
events, 124 collapsed as repeated identities, 246 rows stored. Identical numbers on both.

The 124 lost rows are the visible half. The worse half is that `is_checked_in` and `checkin_date`
are per-event facts, and with no event column on the row each survivor kept a check-in state from
whichever event was fetched last, with nothing recording which.

`eventCode` needs no new fetch work: `BaseRESTIntegrationConnector` already tags every record
fetched through an APIPath template var with the resolved parent id under the template var's own
name, so the value has been arriving all along and being discarded for want of a declared field.

Ships as a delta migration in both dialects, keyed by the seeded row IDs and idempotent, rather
than a re-seed — installed tenants keep their rows and Flyway checksums.

Note for already-built connections: the mirror table keeps its current primary key. The schema
builder warns on a key change and skips it rather than rebuilding a table under live data, so an
existing connection needs that object rebuilt for this to take effect.
