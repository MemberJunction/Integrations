---
'@memberjunction/connector-netsuite': patch
---

NetSuite auth failures now carry the server's own diagnosis, and mode inference cannot be hijacked by leftover OAuth2 keys.

- 401/403 messages (TestConnection, metadata-catalog) include the `WWW-Authenticate` header and `o:errorDetails` — the parts that name token_rejected vs invalid_signature vs timestamp_refused. Previously the reason was discarded and operators saw a bare "HTTP 401".
- `ResolveAuthMode` now prefers a COMPLETE TBA credential set (ConsumerKey+ConsumerSecret+TokenID+TokenSecret) over leftover BearerToken/AccessToken/RefreshToken fragments when no explicit AuthFlow is set. A stale OAuth2 key from an earlier attempt silently flipped the mode and 401'd every request while four valid TBA secrets sat unused. Explicit AuthFlow still always wins.
