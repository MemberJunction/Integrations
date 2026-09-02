---
"@memberjunction/connector-elevate": patch
---

Window filters go out in the vendor's own documented form — comparison-operator keys with full datetimes ({">=": "2021-04-06 00:00:00", "<=": …}) — replacing an invented { date: [from, to] } shape the door silently matched nothing against: every windowed read returned zero rows on tables holding tens of thousands, across three different watermark fields, live.
