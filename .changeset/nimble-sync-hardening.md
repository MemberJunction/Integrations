---
'@memberjunction/connector-nimble-ams': patch
---

Salesforce sync hardening: the five defects that kept a real org from ever finishing a sync.

- **Chunked SOQL projection** — Salesforce's REST edge rejects an over-long request line with
  HTTP 431 (the URI counts against the header budget), so a wide object (Account: 674 queryable
  fields) failed batch 1 of every run. When the encoded projection exceeds 12,000 chars, the
  SAME row window is fetched as several narrower queries (each always carrying Id + the
  watermark field), pinned to one page size (`Sforce-Query-Options: batchSize=200`) so pages
  stay aligned, and reassembled by Id — misalignment THROWS rather than writing half-populated
  rows. A chunked cursor is the JSON array of per-chunk nextRecordsUrl values; narrow objects
  take the exact single-request path they take today.
- **Per-page watermark advance** — the watermark only recorded under `done=true`, so an object
  too big to finish one run recorded nothing and restarted from row zero forever (subsumes the
  standalone per-page PR).
- **Watermark resolution against real fields** + the 120s discovery deadline (subsumes the
  nimble half of the watermark/sampler PR).
- **`StableOrderingKey` → null** — declaring one made the engine run keyset pagination INSTEAD
  of the watermark filter; every sync re-walked from row zero.
- **SOQL datetime literals canonicalized** — Salesforce emits offsets without a colon
  (`+0000`); the colon-only test appended a stray `Z` and every watermarked query died with
  MALFORMED_QUERY (HTTP 400). One canonical form now: UTC ISO `Z`.

All five ran in production for a week as instance patches: the measured result on one org was
~250 → ~20,000 rows/min sustained and a 3.87M-row object reaching source parity.
