# MemberJunction (MJ→MJ) — Supported & Proven

> **Evidence tier:** ⚙️ Synthetic-local (disposable container, structural only)  ·  **Last verified:** 2026-07-26  ·  **Proof DB(s):** —

## What this connector supports

**6 objects** declared across **79 fields** (source: `metadata/integration/.mjtomj.integration.json`). 0 declare a write path; 6 are read-only (pull). 6 support incremental sync.

| Object | Pull | Push (C/U/D) | Incremental |
|---|---|---|---|
| AIAgentRuns | ✓ | — (read-only) | ✓ |
| AIAgentRunSteps | ✓ | — (read-only) | ✓ |
| AIAgents | ✓ | — (read-only) | ✓ |
| ConversationDetails | ✓ | — (read-only) | ✓ |
| Conversations | ✓ | — (read-only) | ✓ |
| Users | ✓ | — (read-only) | ✓ |

> **"Declares a write path" is a capability declaration, not a proven behaviour.** What has actually
> been executed against a live system is in the next section, and nothing else should be read as proven.

## What is proven

### Pull (read)

- **Structural only.** Discovery succeeded against a disposable local container with synthetic rows; no production data.

### Push (write / bidirectional)

- **Status: n/a.** Peer MJ-server introspection over the consumer path.
- **No live write side-effect has been executed or verified for this integration.** Bidirectional is not claimed as "works".

## Residual gap (honest)

- Live **write side-effects** — never executed against a real tenant (needs `allowWrite` + a disposable record).
- **Deletes / tombstoning**, conflict / echo-loop resolution — not exercised.
- **Rate-limit / backoff under load** — not stress-tested.

---

_Capability section derived from this connector's own metadata on 2026-07-28. Proof numbers are DB ground
truth as of 2026-07-26 (`gen-support-docs.mjs`), and are re-stated verbatim — they change only when a
new live sync is run and the doc is regenerated._
