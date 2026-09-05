---
'@memberjunction/connector-elevate': patch
---

Chunked-fetch salvage: a report that dies with an unexplained 500 (some sites kill any report that generates too long — report cost is additive per column) is now fetched in primary-key-joined field chunks instead of being given up. A column whose report dies even when requested alone is quarantined for the connection with a loud warning and the rest of the object still syncs; the proven chunking is remembered per connection+object so later fetches skip the doomed full request. Keyless objects refuse chunk-joining (row order across separate reports is not a contract) and keep the original error, saying why.
