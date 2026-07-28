# Oracle (source DB) — Supported & Proven

> **Evidence tier:** ⚙️ Synthetic-local (disposable container, structural only)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —

## What this connector supports

This connector declares no static object catalog — it discovers what it can read from the system it is pointed at, at connection time. What it supports is therefore whatever that particular instance exposes to the credential you supply.

## What is proven

### Pull (read)

- **Structural only.** Discovery succeeded against a disposable local container with synthetic rows; no production data.

### Push (write / bidirectional)

- **Status: n/a (source leaf).** Read source; native NUMBER/VARCHAR2/DATE mapping confirmed.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
