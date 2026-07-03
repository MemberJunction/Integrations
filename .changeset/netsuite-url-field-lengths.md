---
"@memberjunction/connector-netsuite": patch
---

Declare semantic lengths for url-class string fields (255 default → 2048). Oversize values are skipped, not truncated — silent record loss risk.
