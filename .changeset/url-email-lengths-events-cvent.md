---
"@memberjunction/connector-cvent": patch
---

Declare semantic lengths for url/email-class string fields (255 default → url 2048, email 320). Oversize values are skipped, not truncated — silent record-loss risk.
