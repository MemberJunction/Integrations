---
"@memberjunction/connector-schema-merge": patch
---

Give MEASURED field widths headroom in the sample-union merge: a capped sample reads a bounded number of rows, so the longest value can be outside it — sizing a column to the exact observed max then skips any later record that's even one char longer (this dropped 99 PheedLoop members: `about` measured 2348, a real bio was 2595). Measured widths now round up to the next standard tier (…2048, 4000). DECLARED describe-API widths (Salesforce/Fonteva) stay EXACT — never inflated, never shrunk.
