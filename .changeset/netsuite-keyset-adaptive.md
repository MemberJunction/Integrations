---
'@memberjunction/connector-netsuite': minor
---

Keyset (seek) paging, throttle surfacing, and concurrency-tier alignment for SuiteQL reads.

- **Keyset paging replaces OFFSET.** `?offset=N` makes NetSuite re-evaluate and skip N rows on every page, so a full walk costs O(n²) and each page is slower than the last. Reads now seek — `WHERE id > <last seen> ORDER BY id` — so every page reads only frontier rows at constant cost. `id` is unique, so page boundaries are exact (no skips or repeats, which a timestamp ordering cannot promise). The position is returned as `NextAfterKeyValue` (the engine persists it — durable resume across restarts, which previously never happened because no position was returned by either route) and `NextCursor` (arms the engine's prefetch pipelining). Non-numeric seek keys are rejected before reaching the SQL (injection guard) and fall back to an unseeked page.
- **Absorbed 429s now reach the engine.** The internal retry made a 429 invisible — the fetch ultimately "succeeded" — so the engine kept firing at a rate the account had just rejected. Each 429 is now surfaced via `ctx.RateLimitReport` (with the server's `Retry-After` in the shape `ExtractRetryAfterMs` parses) before the connector backs off, so the engine's adaptive concurrency cap converges on the account's real grant. Transient 5xx retries do not report.
- **`MaxConcurrencyHint` is now 5** — the smallest documented tier's actual grant, rather than sitting under it; the engine's adaptive gate handles accounts whose real grant is lower.
- **Default SuiteQL `limit` is now 100** (per-object/config overrides unchanged): matches the page sizes NetSuite actually serves for many object types, and keeps each request short so concurrency slots recycle quickly on this concurrency-governed API.
