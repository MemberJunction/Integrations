---
"@memberjunction/connector-asana": patch
---

Asana ships its own "Asana API" credential type: personal access token + workspace gid. The connect wizard renders only the credential type's fields, and the generic "API Key" type has one, so a connection could be created with no workspace and then refuse to run ("Asana workspace is not configured").
