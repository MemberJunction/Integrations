---
'@memberjunction/connector-propfuel': patch
---

PropFuel: honour the requested batch size instead of overshooting by a whole file.

The record cap was only checked BETWEEN files, so a single file larger than the cap was emitted in
full: a 1,000-record file answered a 200-record request with 1,000 records. The engine flagged it as
`CONNECTOR_IGNORED_BATCH_SIZE` ("connector returned 1000 records for batch 1 (requested 200)") and
wrote them in chunks, so nothing was lost — but the contract was broken and the ceiling on memory
was one file, not one batch.

A file is no longer the atomic unit. The synthetic cursor may now carry a within-file offset,
`"<microtime>@<n>"`, so a batch can stop part-way through a file and the next call resumes at record
n+1 of that same file. Stopping mid-file keeps the file in the cursor rather than advancing past it,
so records are neither repeated nor skipped.

Cursors written by earlier versions are a bare microtime with no `@`; they parse as offset 0 and
continue to mean "that file is finished", so stored positions keep working across the upgrade.

Covered by tests: a batch of 1 against a 3-record file returns exactly 1; walking a whole feed one
record at a time yields every record exactly once and in order; a legacy bare-microtime cursor does
not re-download the file it already finished; a file that exactly fills the batch leaves a clean
cursor with no phantom offset.
