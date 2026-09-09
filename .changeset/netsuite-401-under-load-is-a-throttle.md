---
'@memberjunction/connector-netsuite': patch
---

Read a 401 on an already-served connection as a concurrency throttle instead of an auth failure.

NetSuite governs by concurrent requests per account, and past the grant it does not always answer 429. Under 8 concurrent fetches it intermittently answered HTTP 401 "Invalid login attempt" mid-walk, on objects whose earlier pages had just succeeded with the same token. Classified as a persistent auth error the page was skipped, the object finished INCOMPLETE, and roughly 58s of retry budget went with each hit — 41 stalls of 10s or more summed 19.9 minutes of one 59.8-minute run.

The connector now treats a 401 as congestion only once this process has watched NetSuite serve a 2xx for that connection (auth mode + account): it backs off like a 429 and reports through `onThrottle`, which is what halves the engine's adaptive fetch gate, so the account's real grant is found rather than guessed. A 401 on the first request of a connection — what a bad or missing credential actually looks like — and any 401 from `TestConnection` stay genuine auth failures, surfaced immediately with no retry. The one case the heuristic can misread, a token revoked mid-run, costs three backoff retries before the same 401 is surfaced unchanged.

`MaxConcurrencyHint` (5, the smallest documented tier grant) already shipped and is what makes the engine's opt-in fetch gate exist at all; a test now pins the value so the gate cannot be silently removed.
