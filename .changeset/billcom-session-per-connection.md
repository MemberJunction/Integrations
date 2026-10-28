---
"@memberjunction/connector-bill-com": patch
---

Key the Bill.com session cache by connection, so one connector instance can never read one organization through another's session.

`Authenticate` returned `this.cachedAuth` whenever a non-stale session was cached, without checking it belonged to the `CompanyIntegration` being authenticated. One instance serving two connections read the second organization through the first one's session; a script that reused a single instance across nine connections got identical data for all nine (#427).

The 401 path was the worse half. `MakeHTTPRequest` re-logged in with `this.cachedCredentials` — whichever connection authenticated most recently — then replayed the original request against that session. A 401 on connection A could therefore come back **200 with connection B's data**, which is the quietest way this could fail.

Both caches are now `Map`s keyed by CompanyIntegration ID + CredentialID + Configuration, so re-pointing a connection at different credentials also cannot keep serving the previous organization's session. `BillComAuthContext` carries its own `ConnectionKey`, because `MakeHTTPRequest` receives only the auth context and so had no other way to know which connection's credentials to re-login with.

Nothing changes for a scheduled sync: `ConnectorFactory` resolves a fresh connector per run, which is the only reason this had not already bitten. It matters for anything that reuses an instance across connections — an action, a script, or a future connector cache.
