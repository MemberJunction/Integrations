---
'@memberjunction/connector-ga4': minor
---

Add the Google Analytics 4 connector (Data API v1beta).

GA4 is not an API with records in it. Every other connector in this repo reads a system that holds
things — contacts, orders, courses — and syncing means listing them. GA4 holds a query engine. There
is nothing to enumerate, so an "object" here is a **defined report**: a fixed set of dimensions and
metrics, declared in `src/GA4Objects.ts`, whose rows are identified by their dimension tuple. Three
consequences follow, and they shape everything else in the package.

**`date` is a dimension on every object.** A report aggregated over a range is a single answer whose
shape changes the moment the range moves — resync it a day later and every number is different, with
no way to tell which rows changed. Adding `date` turns that into one stable row per day, which is the
only form that can be upserted across runs.

**Three objects, not one, because GA4's user metrics do not add up.** `totalUsers` and `activeUsers`
are cardinalities: GA4 de-duplicates them *at exactly the grain you asked for*. Summing a finer grain
into a coarser one double-counts every visitor who appears in more than one bucket, by an amount the
data cannot tell you. `sessions`, `engagedSessions`, `screenPageViews`, `keyEvents` and
`userEngagementDuration` are additive and do roll up. So each grain that anyone needs user counts at
must be its own `runReport` call:

- `PagePerformance` — `(date, pagePath)`
- `UtmPerformance` — `(date, sessionCampaignName, sessionSource, sessionMedium)`
- `UtmContentPerformance` — the same plus `sessionManualAdContent`, for A/B variant comparison

Ratio metrics are deliberately absent from all three. They are non-additive *and* derivable from
columns already present, which is the worst of both — a stored quotient that cannot be re-aggregated
and did not need storing.

**`keyEvents`, not `conversions`.** Google renamed the metric in the Data API's May 2024 changelog
(`isConversionEvent` → `isKeyEvent`, and so on). The old names still resolve for back-compat; this
connector ships the current ones.

**A lookback window, because GA4 data is not final when the day ends.** Events reprocess for up to
48 hours and user-scoped metrics keep moving after that, so a watermark that only ever reads forward
permanently captures each day at its least accurate. `Configuration.lookbackDays` (default 3)
backdates the start of each window; the engine's content-hash prefetch makes re-reading an unchanged
day cost reads and zero writes.

**The watermark is the run's own pinned `today`, not the maximum date in the data.** Using the data's
maximum would strand the watermark behind a quiet weekend and re-read the same empty range forever.
The pinned clock also lives in the cursor (`today|from|to|offset`): the date range is derived from
watermark + clock, and the engine does not advance the watermark until a run ends, so a run that
crosses midnight would otherwise recompute a *different* range and resume a stale offset into it.

**`maxWindowDays` (default 90) bounds each request, not each run.** When a window is exhausted the
cursor advances to the next one within the same run, so a cold backfill of a year finishes in one
run rather than one run per window. Narrow windows also keep each request inside GA4's cardinality
limits, where wide ones start collapsing rows into `(other)`.

**One `runReport` per `FetchChanges` call.** `FetchChangesMs` is 30 000 with no per-connector
override, a timeout classifies as retryable, and `WithTimeout` is a non-cancelling `Promise.race` —
so an overrun is not a clean retry, it is the same query running three times concurrently.

**Composite keys can exceed the record map's column.** `CompanyIntegrationRecordMap.ExternalSystemRecordID`
is `nvarchar(750)`, and `utm_campaign`/`utm_content` are free text on someone else's tracking
template. Above 700 characters `buildExternalID` substitutes `ga4:<sha256>`. Truncating instead would
merge two distinct campaigns into one row and silently blend their numbers — a wrong answer, where
overflow is only a missing one.

Credentials are a Google service-account key held in `MJ: Credentials` under a new
`Google Service Account` credential type; nothing is read from `Configuration`, from the legacy
`GA4_SA_JSON` environment variable, or from `CompanyIntegration.APIKey`. Two setup failures get
named explicitly rather than surfacing raw: a key that has been through a JSON round-trip arrives
with literal `\n` escapes and fails deep inside OpenSSL, so it is un-escaped on load; and a service
account can authenticate with the Data API enabled and still be unable to read a property, because
property access is granted in Google Analytics → Admin → Property Access Management, a different
product from Cloud Console. `TestConnection` says so, and names the `client_email` to add.

Fetches also surface what GA4 reports about its own answer: `CARDINALITY_LIMIT` when rows were
collapsed into `(other)` (the rows still land — dropping them would silently shrink every total),
`DATA_THRESHOLDED` when results were withheld for small-audience privacy, `QUOTA_EXHAUSTED` when the
hourly token bucket is spent, and `UNKEYABLE_ROW` when a row came back without a usable date.
