---
'@memberjunction/connector-totara': patch
'@memberjunction/connector-openwater': patch
---

Both connectors now hold a read deadline that a stalled vendor cannot slip past.

A vendor that accepts the connection and then goes quiet is the failure mode with no artifact: it is not a
failed run, it produces no error, and it writes nothing anyone can read. It was observed twice on Totara as
wedged worker processes that had to be killed from outside the system. Two different bugs, same shape.

**Totara had no deadline at all.** `MakeHTTPRequest` called bare `fetch` with no signal, so a silent site
hung the fetch forever. It now passes `AbortSignal.timeout` with a deadline resolved once at `Authenticate`
— default **25000ms**, deliberately under the engine's `FetchChangesMs = 30000` kill so the connector
reports the failure itself instead of being killed mid-batch and persisting nothing. An abort is translated
into an ordinary error naming the function and the deadline (`core_enrol_get_enrolled_users did not respond
within 25000ms`), so the engine retries it like any other transport failure and the run artifact records
why. Non-abort errors are re-thrown untouched — a refused connection must not be relabelled as a timeout.
Override per connection with `requestTimeoutMs` in `CompanyIntegration.Configuration`; `0` opts out, for a
site whose functions are legitimately slower than any sane default.

**OpenWater had a deadline that disarmed itself at the worst moment.** It paired an `AbortController` with
`clearTimeout` in a `finally` around the `fetch` call — but `fetch` resolves when the **headers** arrive,
and the body is read afterwards in `BuildRESTResponse`. The timer was therefore cleared at exactly the
instant the response body began streaming, so a vendor that answered with headers and then stalled mid-body
hung indefinitely regardless of the configured timeout. Replaced with `AbortSignal.timeout`, which stays
armed for the life of the signal, body stream included, and needs no manual teardown. A fresh signal per
attempt is correct and is now pinned by a test — retries must not share one expiring deadline.

Six unit tests across the two: signal present, abort translated and named, non-abort passed through, `0`
opts out, the signal still armed after headers arrive, and one deadline per retry attempt.
