---
'@memberjunction/connector-totara': patch
---

Every Totara request now ENDS, and a source that never short-pages is cut off loudly

Two boundedness gaps, both of which turned a misbehaving remote into an unrecoverable hang:

- **`RequestTimeoutMs: 0` meant no AbortSignal at all.** The opt-out exists because some
  wsfunctions on some sites genuinely run past the 25s default — but a request that never
  finishes its body then held its call forever, and because the creation pipeline writes its
  result only from complete()/fail(), the run kept a start event, no terminal event, and
  `isInFlight` stayed true for good, unclearable by any client. `0` now opts out of the
  default, not out of ending: an absolute ten-minute deadline stays armed, and a terminating
  request produces an error the engine can retry and the run artifact can record.

- **A wsfunction that ignores the offset parameters returned the same full page forever.** The
  per-parent paged loop's only exit was a SHORT page, which trusts the source to honour
  `limitfrom`/`limitnumber`. When it doesn't, the loop never breaks, duplicates pile up, and
  every turn issues another perfectly successful request — indistinguishable from a hang from
  outside. Parents are now cut off after `MAX_PAGES_PER_PARENT` (2000) consecutive full pages,
  the walk finishes, and a `PARENT_PAGINATION_NOT_HONOURED` warning names the parents, the
  wsfunction, and why the cut-off data should not be trusted as complete.

Tests 86 → 87 (the old "0 opts out — no signal" test now asserts the cap is armed instead).
