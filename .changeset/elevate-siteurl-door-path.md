---
'@memberjunction/connector-elevate': patch
---

Accept a site URL that already carries the door path.

`siteUrl` can be supplied with `/api/reports` on the end — the form a client is often given.
`GetBaseURL` returns `siteUrl` verbatim (it only strips trailing slashes) and `JoinURL` then appends
the object's own door, so every request went to `…/api/reports/api/reports`. That 404/405s,
`ValidateResource` swallows the error and returns false, and `TestConnection` reports:

> The Report API door rejected a minimal query for resource "ProductRegistration". Check the site URL
> and the API key issued for this site.

Both named suspects are innocent. Observed against a real deployment where the API key was valid and
every declared resource was reachable — including the exact resource and field the failing probe used.
The connection simply could not be saved, and the message sent the operator to re-check a credential
that was already correct.

`Authenticate` now normalises the configured value through a `NormalizeSiteUrl` helper that removes a
trailing door path: `/api/reports`, its `/form` variant, and `/api/registrations` — the three the
connector can append. Only a WHOLE trailing segment is stripped and the match is case-insensitive, so a
site genuinely served from a directory (`/lms`, or a path merely sharing a prefix like
`/api/reportsdata`) is left exactly as configured.

Eight tests cover it: each door form and a differently-cased one normalise to the site root; three
legitimate paths survive untouched; and an end-to-end read asserts the door is appended exactly once
when `siteUrl` already carried it.

Behaviour is unchanged for every connection already configured with a bare site root. No metadata,
objects, fields or capability flags change — this is code only.
