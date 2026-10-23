---
"@memberjunction/connector-informz": minor
---

Add the Higher Logic Thrive Marketing Professional (Informz) connector.

Advanced API (AAPI) is a single-door WCF SOAP service: one operation, `PostInformzMessage(string)`,
carrying GridRequest (read) and ActionRequest (write) XML documents. 70 objects / 1,010 fields
covering subscribers and their tenant-defined demographics, interests and personas; mailings and
mailing instances; per-mailing activity (opens, clicks, bounces, opt-outs, forwards); campaigns; web
tracking; scoring; target groups; and suppression.

- In-body credentials (`<User>`, `<Password>`, `<Brand id>`) with a Higher Logic IP-allowlist
  precondition, and credential scrubbing that covers both the raw document and the XML-escaped form
  it takes inside the SOAP envelope.
- Offset paging via `SortField`/`StartRow`/`NumberOfRows`, capped at the vendor's 1,000-row maximum.
- Incremental sync on 23 objects via GTE watermark conditions.
- Runtime sample-union discovery promotes tenant-defined demographic and interest columns to
  first-class columns rather than routing them to custom overflow.

Evidence: mock-only. Full end-to-end sync through MJAPI into SQL Server against a mock vendor server
(248/248 records, 68/68 syncable objects with rows, idempotent re-run), verification ladder T0–T7
green, and floor-check clean across all 66 bijection slots. No authenticated call has been made to a
Higher Logic tenant. Higher Logic's separate Push API v2 (`datapushapi.higherlogic.com/v2`) is out of
scope for this connector.
