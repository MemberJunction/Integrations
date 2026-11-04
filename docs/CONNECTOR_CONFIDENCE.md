# Connector confidence — 2026-11-04

How good we feel about each connector that has actually been exercised on an environment, scored on five measures from the live fleet, the code, and the team's working history. Spreadsheet with every measure and column: [`data/connector-confidence-2026-11-04.xlsx`](data/connector-confidence-2026-11-04.xlsx). Counts are customer-only; no organisation is named.

**Overall** = (M1 Code maturity + 2·M2 Production proof + 2·M3 Operational stability + M4 Data-model coverage + M5 Team knowledge) / 7. High ≥ 3.5 · Medium 2.5–3.4 · Low < 2.5.

| Connector | Category | Complexity | Customer envs | Scheduled | Runs (window) | Success | Records (window) | Tables | M1 | M2 | M3 | M4 | M5 | **Overall** |
|---|---|:-:|:-:|:-:|:-:|:-:|--:|--:|:-:|:-:|:-:|:-:|:-:|:-:|
| NetForum Enterprise | AMS | 5 | 2 | 1 | 105 | 92% | 3,340,960 | 830 | 3 | 5 | 3 | 4 | 5 | **4.0** (High) |
| PheedLoop | Events | 2 | 1 | 1 | 100 | 77% | 78,441 | 27 | 4 | 4 | 4 | 3 | 4 | **3.9** (High) |
| Elevate (LMS) | LMS | 3 | 1 | 1 | 100 | 94% | 15,001,870 | 23 | 3 | 4 | 4 | 3 | 4 | **3.7** (High) |
| OpenWater | Events | 4 | 2 | 0 | 3 | 67% | 224,063 | 46 | 4 | 3 | 3 | 3 | 3 | **3.1** (Medium) |
| Nimble AMS | AMS | 4 | 1 | 0 | 0 | — | 0 | 364 | 4 | 3 | 2 | 4 | 4 | **3.1** (Medium) |
| NetSuite | Finance | 4 | 1 | 0 | 18 | 62% | 1,140,914 | 461 | 3 | 3 | 2 | 4 | 4 | **3.0** (Medium) |
| PropFuel | Marketing | 2 | 2 | 0 | 18 | 44% | 1,547,716 | 3 | 4 | 3 | 2 | 2 | 2 | **2.6** (Medium) |
| WordPress | Platform | 4 | 1 | 0 | 1 | 100% | 18,472 | 17 | 3 | 2 | 3 | 2 | 3 | **2.6** (Medium) |
| rasa.io | Marketing | 2 | 1 | 0 | 4 | 50% | 380,031 | 23 | 3 | 2 | 2 | 3 | 3 | **2.4** (Low) |
| Spektrix | Events | 3 | 1 | 0 | 1 | 100% | 57,450 | 28 | 2 | 2 | 3 | 2 | 2 | **2.3** (Low) |
| HubSpot | CRM | 4 | 0 | 0 | 0 | — | 0 | 0 | 4 | 1 | 2 | 4 | 2 | **2.3** (Low) |
| Totara | LMS | 4 | 1 | 0 | 6 | 0% | 665,946 | 29 | 3 | 2 | 1 | 2 | 4 | **2.1** (Low) |
| ORCID | Platform | 3 | 0 | 0 | 0 | — | 0 | 0 | 4 | 2 | 1 | 3 | 2 | **2.1** (Low) |
| Asana | PM | 1 | 0 | 0 | 0 | — | 0 | 0 | 3 | 1 | 2 | 2 | 2 | **1.9** (Low) |
| Dynamics 365 Business Central | Finance | 4 | 0 | 0 | 0 | — | 0 | 0 | 4 | 1 | 1 | 4 | 1 | **1.9** (Low) |
| Google Analytics 4 | Marketing | 2 | 0 | 0 | 0 | — | 0 | 0 | 3 | 1 | 2 | 2 | 1 | **1.7** (Low) |
| Everhour | PM | 1 | 0 | 0 | 0 | — | 0 | 0 | 3 | 1 | 2 | 2 | 1 | **1.7** (Low) |
| Informz (Higher Logic Thrive Marketing) | Marketing | 4 | 0 | 0 | 0 | — | 0 | 0 | 2 | 1 | 1 | 2 | 1 | **1.3** (Low) |

## How we feel, per connector

### NetForum Enterprise — 4.0 (High)

*SOAP (xWeb netForumXML GetQuery) / session token from Authenticate / incremental on 23 of 34 declared objects via date watermark; keyset paging; live discovery enumerates ~890 objects*

Our most battle-tested connector and our most expensive. One customer runs it nightly on ~820 tables with 92% success and millions of rows (PROVEN: 15M rows across 380 tables, nine core tables matching the vendor's counts); a second customer's first install is still being brought up. We know every failure mode because we have hit all of them. High confidence that we can run it and recover it; not a hands-off connector — a new tenant needs the current patch set, a sized box, one-at-a-time addition of wide tables, and someone watching the first full load. The vendor's ~100-faults/day account lock is the one thing we cannot undo ourselves.

- **Effort spent:** Very high — the largest support thread of the year, from the first xWeb account lock (Sept) through discovery OOM, keyless whole-table sampling, GUID keys used as columns, fault-budget learning, memory-governor false trips, off-heap page pinning, scheduler double-dispatch and a direct bulk-load path. Dozens of sessions, 1.5.0 → 1.7.0 in six weeks, several tenant hotfix patch sets; 1.7.1 still open upstream.
- **Known defects:** FIXED: '*' column lists burning the xWeb fault lock (1.3.3); enumeration/DiscoverFields (1.6.x); fault latch PROVEN 0 faults in 49k events; keyless sampling OOM (#400); GUID obj_key as column (1.6.5); faults paid once + learned state + own-table fallback (1.7.0); keyset resume after last row; PG unbounded width (#1996); scheduler re-dispatch (MJ-SCHED-01, tenant patch). OPEN: 1.7.1 (#481/#482) not merged; runs report Success with every object aborted; ~820 entities exceed MJ metadata limits (facade timeout, Explorer OOM build); the newest customer install has 1 stuck run and 3 of 5 runs failed.

### PheedLoop — 3.9 (High)

*REST v3 / static API key + secret headers / mostly full refresh (4 of 28 objects incremental); page-number paging; rate-limit policy with backoff*

The connector we would hand to a new customer with the least worry: a simple API and a nightly schedule that has run on a customer since mid-October with 77% success in the window — and every one of those failures dates from before the customer's 10-29 database upgrade; it has been clean since. Internally it has 100 consecutive nightly successes since July. The blemishes are operational noise (duplicate never-run instances from wizard retries) rather than connector defects, and Create is the only write wired.

- **Effort spent:** Moderate — the fleet's longest-running scheduled connector (an internal instance has 100 straight nightly successes since 2026-07-28). Work went into migration repairs, the door-pagination cap, a shared-discovery corruption of 487 declared fields (#1721), and one customer's half-upgraded database that broke metadata refresh (10-22, superseded by the 10-29 upgrade). Also used as the 6.1.6 canary smoke test.
- **Known defects:** FIXED: door-pagination cap; shared discovery corrupting declared fields (#1721); half-upgraded-DB refresh failure (upgrade 10-29). WORKAROUND: schema refresh overwrites field widths (declare widths in additionalSchemaInfo). OPEN: first HTTP 429 aborts the run (AIMD reacts too late); entities register without an Application; upstream PG codegen TS2724 bug; its 'Events' table collides with NetForum's on a shared tenant; one customer connection and five internal instances were created and never run (wizard retries); one internal instance fails every night (dead credential, not connector code).

### Elevate (LMS) — 3.7 (High)

*Single POST report door (/api/reports) with SQL-like filters / API key in the request body / date-windowed incremental on the watermark field; vendor ignores paging*

Quietly one of our best performers: ~100 nightly runs on a customer at 94% success, 15M records in the window, 21 of 23 resources syncing (PROVEN 152k processed on 10-15). The 0.3.x version and the mock-only SUPPORT.md undersell it. The remaining failures are the vendor's two 500-ing resources. Confidence is good for the one deployment pattern we have; a second customer with a different site catalog would be the real test.

- **Effort spent:** Moderate-high — first-contact kill chain (0.3.2: label poison, no 500 retry, wrong window wire shape), a month of 'no read-surface columns' traced to cold fields under crossLayerPipeline (MJ-RUN-54 fix reverted after guard kills), 22 of 23 maps found disabled with no schedule (10-12), route-resolution fix 0.3.7 (10-15), a type-loss thread (all 553 fields nvarchar; tsvector typed Int broke 11 entities' record loads).
- **Known defects:** FIXED: 0.3.2 kill chain (0.3.4); route resolved before catalog loaded (0.3.7, live 10-15); maps disabled / no schedule; MJ 6 peer range. WORKAROUND: keep crossLayerPipeline=false; geocoding off on User/EarnedCredit. OPEN: vendor returns HTTP 500 for quizAccess and quizAnswer on every request; declared types lost (all nvarchar) and the retype is reverted by 'Refresh schema'; ProductRegistration never exercised.

### OpenWater — 3.1 (Medium)

*REST Public API v2 / X-ClientKey + X-ApiKey headers / incremental on 11 of 46 objects; pageIndex paging plus concurrent parent-detail walks for child objects; 3 req/s rate policy*

Good code and full coverage (all 46 objects materialise as tables), run on two customer environments and two internal connections — but only by hand, a handful of runs each, never on a schedule. 2 of 3 customer runs succeeded. We would be comfortable scheduling it; nobody has yet, and the open child-path 404s mean a few objects will stay empty until fixed.

- **Effort spent:** Moderate — an unbounded detail walk that killed a container (door paging, #223/#229), a Redis-cached EMPTY field list that made discovery skip every object (MJ-RUN-55, PROVEN 34→4), credential-type and one-field-credential-form diagnosis on an Azure tenant, repeated catalog growth. Two customer environments (one destroyed since) and two internal connections have run it.
- **Known defects:** FIXED: unbounded detail walk (#223/#229); stale empty field cache (MJ-RUN-55 / #1877); credential type NULL. OPEN: embedded child paths unresolved (404s) and /v2/Funds 401 (INT-1/INT-2); credential form shows one field (MJC-3); integer FKs become NVARCHAR(MAX) and are unindexable; no live write; a stale 'Failed' install row on one customer's control plane while the tenant runs 1.4.1.

### Nimble AMS — 3.1 (Medium)

*Salesforce-native (extends the Salesforce connector): SOQL/REST + Nimble Fuse Apex REST + LMS REST / OAuth2 client credentials / incremental on 31 of 32 objects via LastModifiedDate; SOQL cursor paging*

Proven at volume more than once (11M rows on a customer dev environment, 9M in the internal window, 364 tables) and the code is mature, but nothing is syncing on a schedule today and the engine path still carries the watermark and batch-size defects we patched per-instance. Confidence in the connector is decent; confidence that a deployment stays healthy without us is not yet earned.

- **Effort spent:** High — bundle-shadowing of patches (which copy runs was not stable across boots), SQL Server apply that built 16 of 364 tables (MJ-APPLY-01 / #1892-#1894: CodeGen skipped 348 entities, 1,044 procs missing), a 10.97M-row bulk load on a customer's dev environment (09-28), 3.87M rows on its since-destroyed stage, 4.93M rows on the sandbox (10-19); the incident that set the 'never read client table data' rule.
- **Known defects:** FIXED: bundle shadowing (mirrored); SQL Server apply/CodeGen gaps (#1892-#1894); sync blockers (0 → 7,221 Contacts). OPEN: watermark only advances when the query reports done, so big objects restart from zero; BatchSize ignored (2,000 rows returned for 200 requested → sandbox OOM); Account chunked projection / per-page watermark / date-literal patches not upstream (#206 closed unmerged); orphan activeSyncs block start after a restart; the customer dev environment has 364 maps and no engine run rows (data arrived via the bulk loader).

### NetSuite — 3.0 (Medium)

*SuiteTalk REST Record Service + SuiteQL / OAuth 1.0a token-based auth (HMAC-SHA256) or OAuth2 / incremental on 203 of 205 objects via lastModifiedDate + keyset; offset paging*

Big surface with real customer data behind it (461 tables, 1.1M records; PROVEN 201,837 records in 17 minutes with zero errors), but the run history is rough — 62% success, cancelled and stalled runs, nothing run for a month, and a throttle fix that regressed. We understand the API and its concurrency tiers well; we do not yet have a deployment that just works.

- **Effort spent:** High — O(n²) paging rewritten to keyset (#278), prefetch frozen at 200 rows (#4089), 31-second throttle backoffs (#4088; regressed in the 5.51 re-cut, workaround fetchConcurrency:5), per-page watermark ratchet that reported 707 of 23,558 Vendor Bills as success (MJ-DISC-17), 65,203 silent write failures from stale CRUD procs (MJ-RUN-7), a reset script because full reloads were needed more than once, 16 record types retired after live failures.
- **Known defects:** FIXED: keyset paging (#278); prefetch advance (#4089); watermark ratchet (MJ-DISC-17, on next); 16 record types retired. REGRESSED: throttle backoff fix lost in the 5.51 re-cut (workaround in config). OPEN: stale-CRUD-proc write failures need a CodeGen regen each time; FetchChangesTimeoutMs patch-only (#341 behind); wizard configs lack writeMode; install failed on a partner-prospect Azure environment; no runs in the last 30 days on the customer dev environment (10 success / 6 failed / 2 cancelled in the window).

### PropFuel — 2.6 (Medium)

*File feed (data-export API lists and downloads hourly JSON files) / bearer token + account id / incremental via a client-side file cursor; objects discovered from filename suffixes*

Simple and widely installed (two customer production environments, three connections), tiny data model (clicks, opens, check-in questions), 1.5M records moved. The 44% run success has never been investigated, so stability is unknown rather than known-bad. Low risk, low ambition.

- **Effort spent:** Low — a CodeGen hang on 'Apply All' (OpenRouter routing, fixed in the template), App Manager install gotchas (monorepo subpath, blank version, green on failed upgrades), measured live in September; usually installed alongside PheedLoop.
- **Known defects:** FIXED: CodeGen hang (#63). OPEN: one zero-field object in the catalog; across two customer environments 8 of 18 runs succeeded, one connection is failing now and one never ran — the failures have not been triaged, so no code defect has been isolated.

### WordPress — 2.6 (Medium)

*REST wp/v2 + WooCommerce wc/v3 + a companion PHP plugin (mj-wsal) / HTTP Basic with an application password / incremental on 11 of 84 objects via modified_after; per-site route discovery*

Works for the narrow case we have run — one successful customer run over a 16-object site (18k rows) — while the full 84-object model has never completed anywhere and the sandbox proof surfaced silent data loss (rows and fields dropped without an error). Treat as 'good for a curated subset', not 'point it at any site'.

- **Effort spent:** Moderate — an apply that built 0 tables twice (#1940/#1942, deployed 10-20), 4 of 112 maps without field maps (MJ-APPLY-19 / #1966), a findings session on the sandbox (10-29) that exposed MJ type and catalog defects, first customer run 11-03.
- **Known defects:** FIXED: 0-map apply (#1940/#1942); maps without field maps (#1966). OPEN (PROVEN on the sandbox): declared fields never reach an existing connection's catalog; 24 field maps target missing columns and drop silently; 153 rows skipped whole on string overflow; Length 4000 stamped on bit/datetimeoffset; run list resets every deploy; full first sync never completed even against the mock (9 objects unplaced); no write ever executed.

### rasa.io — 2.4 (Low)

*REST v2 / OAuth2 client credentials → Bearer / incremental on 5 of 23 objects with a lookback window; offset paging*

Fresh rebuild, one customer, four runs, half failed, latest one failed. It moved 380k records so the pipe works; it has not yet proven it stays up. Watch the next two weeks before calling it stable.

- **Effort spent:** Moderate — rebuilt for the vendor's v2 API (3.0.0), a half-install on the sandbox from an App Manager 90-second list false negative (#1981), MJ 5.51 scope-denial nulls and user-API-key scope work for the vendor's read access to a customer tenant, first customer runs 11-03.
- **Known defects:** FIXED: v2 rebuild; key scopes (read-only on 4 entities, PROVEN); scope-denial nulls (MJ 6.1.2+). OPEN: half-install false negative (#1981 merge not recorded) — do not uninstall/re-add; 2 of 4 customer runs failed and the latest run failed after the last success; stale 'Failed' install row on the sandbox.

### Spektrix — 2.3 (Low)

*REST API v3 / HMAC-SHA1 signed requests / full refresh only (0 of 65 incremental); no paging declared*

Two weeks old, one customer, one successful run of 57k records. Promising but unproven; full-refresh-only will hurt as the dataset grows and the second run has not happened.

- **Effort spent:** Low — built in October for one customer; on-box artifact-replay and error scripts from its first run are the only operational history.
- **Known defects:** OPEN: no incremental, so every run is a full refresh; 28 of 65 objects materialised; one run ever (12 days ago); no SUPPORT.md and no tests beyond fixtures.

### HubSpot — 2.3 (Low)

*REST CRM v3 objects + search API / private-app token as Bearer / incremental on 79 of 168 objects via lastmodifieddate search filters windowed under the 10k search cap; cursor paging*

Large, well-built, and unused by any customer. The one internal install's state could not be read. Code confidence is good; operational confidence is theoretical.

- **Effort spent:** Low-moderate — 130 objects discovered in a live test (07-24), an undeclared schema-merge dependency (1.1.1), hs_object_id primary key (#94), MJ 6.1 seed collision, keyset-anchor fix (10-28); installed on the internal analytics environment and on early HotGlue-era dev environments that are all dead now.
- **Known defects:** FIXED: keyset anchor (10-28); watermark ratchet (upstream). OPEN: writes never verified; seed collision on MJ 6.1 noted in the upgrade plan; the only live install is internal and its tenant API could not be read, so current sync state is unknown.

### Totara — 2.1 (Low)

*Moodle web-service RPC (wsfunction=…) / web-service token / full refresh only (0 of 33 incremental); multi-hop parent chains and ID-window scans for users*

The API is slow and the connector fights it; a lot of engineering has gone in (50 commits) and we still do not have a completed engine run on the customer environment — the rows that exist came from the bulk loader. Low confidence until the boolean coercion is fixed and the enrolment walk is redesigned.

- **Effort spent:** High relative to outcome — build blocker (#105), the enrolled-users slowness triad (#129), a 30-second fetch constant (partner PR), change tracking on all 29 entities filling a customer's database quota (500k rows), ~130k rows loaded by the manual bulk loader (09-28) because the engine managed ~895 records/min on a ~54 ms-per-record serverless round trip.
- **Known defects:** FIXED: build blocker; slowness triad; fetch constant. OPEN: engine coerces booleans into integer columns so every Users row fails; Cohorts 99/99 failed with no events; a map to a missing column drops data silently; exact-repeat duplicates (#204) and #342 failing CI; 6 objects access-denied; 0 successful engine runs in the window (2 failed, 4 cancelled).

### ORCID — 2.1 (Low)

*REST Public API v3 / OAuth2 client credentials (read-public) / incremental on all 18 objects via per-record watermark; iD universe from Lucene search or explicit lists*

Mature code and a documented production consumer in July, but nothing in the fleet runs it today, the current version has never been exercised live, and the July enumeration defect is still open. Confidence rests on history, not on anything we can watch.

- **Effort spent:** Low-moderate — 12 objects passed the discovery campaign (07-24), a dedicated worktree, the 1.3.0 derived model; the same App Manager half-install false negative as rasa on the sandbox (10-29).
- **Known defects:** OPEN: unbounded iD enumeration hits the 30-second timebox and reports Processed: 0 (since July); 1.3.0 derived model never run live; the only MJC install is a half-install on the internal sandbox (stale Failed row, no connection).

### Asana — 1.9 (Low)

*REST v1.0 / personal access token / incremental on 1 of 4 objects via modified_since; cursor paging; read-only*

Small and simple; fine for our own workspace. Installed on a customer environment but never connected there.

- **Effort spent:** Low — ported from the legacy internal driver; credential-type PR #451 (10-20); two small worktrees for a 404 fix.
- **Known defects:** OPEN: installed on one customer dev environment and two internal ones with no connection anywhere; one internal install row Failed (stale — the tenant runs 0.2.4); the internal analytics tenant could not be read.

### Dynamics 365 Business Central — 1.9 (Low)

*OData v4 (BC API v2.0 + web-service pages), $batch writes / OAuth2 client credentials (Entra app) + company GUID / incremental on 57 of 84 objects via $filter watermark; nextLink paging*

Well-engineered against a test tenant, including live writes, but it has never been installed successfully on an MJC environment. Strong code, zero operations.

- **Effort spent:** Low-moderate — the live sweep found 11 catalog path defects the mock suite had passed; one install attempt on the internal analytics environment was cancelled.
- **Known defects:** OPEN: the only MJC install Failed (cancelled run) — no connection anywhere; writes live-proven only for journals; 37 objects reachable but empty.

### Google Analytics 4 — 1.7 (Low)

*GA Data API v1beta runReport / service-account JSON → OAuth2 / incremental on all 3 report objects by date window; offset paging up to 250k rows*

Internal-use only so far. No reason to expect trouble, no evidence either.

- **Effort spent:** Low.
- **Known defects:** OPEN: installed only on the internal analytics environment, whose tenant API could not be read; no customer exposure.

### Everhour — 1.7 (Low)

*REST v1.2 / API key header / incremental on 1 of 4 objects (time records by date); page-number paging; read-only*

Internal-use only. Trivial surface; nothing to worry about and nothing to point to.

- **Effort spent:** Low.
- **Known defects:** OPEN: internal install only; sync state unreadable.

### Informz (Higher Logic Thrive Marketing) — 1.3 (Low)

*SOAP (single PostInformzMessage op carrying XML GridRequest docs) / username, password and brand id inside each request; brand IP registration required / incremental on 6 of 70 objects; StartRow offset paging*

Two weeks old and has never spoken to the real service. Do not promise it to anyone until an IP-registered live run exists.

- **Effort spent:** Low — built 2026-10-23, four commits.
- **Known defects:** OPEN: never authenticated live (needs brand IP registration); 46 of 67 primary keys inferred and unverified; install row Failed on the sandbox (stale; tenant has 0.2.0) with no connection.

## Method & caveats

- Scope: public-catalog connectors from the Integrations repo that have been exercised somewhere — a connection on a live tenant, or an installed/attempted app on an active environment — as of the 2026-11-04 fleet snapshot. Private-repo connectors (ACGI Association Anywhere, ACGI Certelligence, the IRS BMF and 990 reference feeds) are excluded. Of 63 connector folders in the repo, 45 have never been installed on any environment and are not in this sheet.
- Fleet evidence: every environment on the production control plane was read (254 registered, 75 active, 25 answered the tenant API). Per tenant we read integration metadata only — connections, run rows (status, start, end, record count), entity maps, installed apps, entity counts by schema. No synced data rows and no credentials were read. Environments were classified customer / prospect / internal from their organisation's admin email domains and known client list; that classification drives the customer-vs-internal split and no organisation is named here.
- Customer columns count only environments owned by paying or contracted clients (production and development alike — 'Customer envs' shows the split). 'Customer connections' can exceed 'Customer envs' when a customer created more than one instance of the same connector; never-run duplicates are counted in 'Connections never ran'. Internal and demo evidence is summarised in one column and does not feed the customer numbers.
- Snapshot tooling caveat: the 30-day counts exclude runs started in the final 24 hours before the snapshot (a window bug found and fixed after the sweep ran), so 'Runs last 30d' and 'Success rate (30d)' are slightly conservative for nightly connectors and empty for connectors whose only runs fell in that day. 'Consecutive successes', 'Median run (min)' and 'Stuck runs' need per-run rows that this sweep did not persist and are blank; the next sweep fills them.
- 'Runs in window': each connection keeps only its last 100 run rows, so a nightly connector shows at most 100 per connection. 'Records moved' sums TotalRecords over those rows — a window, not a lifetime total. 'Success rate (window)' = Success / (Success + Failed); cancelled runs are shown but excluded from the rate. 'Runs last 30d' and 'Success rate (30d)' count runs started in the 30 days before the snapshot. 'Consecutive successes' is the longest unbroken run of successes at the head of any customer connection's history. 'Median run (min)' uses successful runs under 24 h (hand-closed stale runs are excluded).
- 'Connections failing now' = the connection's latest failure is newer than its latest success. 'Stuck runs' = run rows still In Progress more than 24 h after they started. 'Control-plane install rows Failed (stale / real)': stale = the control plane says Failed but the tenant reports the app installed and versioned (bookkeeping lag); real = the tenant has no such app.
- One internal analytics environment carries installs of Asana, GA4, Everhour, HubSpot and Business Central, but its tenant API returned null for every read; those installs are counted and their sync state is marked unknown.
- Code evidence: package version, source and test line counts, commit counts (total / fix-prefixed / last 60 days) and the SUPPORT.md evidence tier come from the repo on the same day. First-commit dates of 2026-06-25 are the connector import into the monorepo, not when the connector was written. SUPPORT.md is stale for NetForum, Elevate, Rasa, NetSuite (later live-tenant commits contradict it).
- Measures (1-5 each): M1 Code maturity (version, tests, fix ratio, doc evidence tier) · M2 Production proof (customer environments, connections, scheduled syncs, run count, records, duration of sustained use; internal evidence counts for less) · M3 Operational stability (success rates, failing-now and never-ran connections, stuck runs, real install failures) · M4 Data-model coverage (objects vs tables materialised, incremental share, writes, known silent-drop defects) · M5 Team knowledge (how much we have worked on it, whether failure modes and fixes are known). Overall = (M1 + 2·M2 + 2·M3 + M4 + M5) / 7, a live formula — change a score and it recomputes.
- 'Effort spent' and 'Known defects' are drawn from the team's working notes, handoffs and patch/PR history (2026-07 to 2026-11-03); they are summaries, not an issue-tracker export. OPEN means open at the snapshot date; PROVEN marks facts the notes recorded as measured or reproduced rather than inferred.
- Framework defects every connector inherits (not repeated per row): a pull map with no field maps fetches then refuses every record (MJ-RUN-61, open upstream); a schema refresh on cold fields disables maps and clears rows (MJ-APPLY-20, open; platform fix #1993); the scheduler can re-dispatch a running job (MJ-SCHED-01, tenant patch only); a run can report Success while every object aborted; a restart orphans concurrent syncs and resumes them serially; rate adaptation cannot rescue a fetch aborted by its first 429; run history is pruned to 100 rows; patches are applied per instance, never fleet-wide.
- Not connectors and excluded: 'File Feed' and 'Betty AI' integrations registered by default on every tenant; the database connectors (PostgreSQL, SQL Server, MySQL, Oracle, MongoDB, Snowflake) whose sync logic lives in MemberJunction core; HotGlue-era HubSpot registrations on long-dead development environments (mentioned in the HubSpot row).
