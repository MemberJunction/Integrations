---
"@memberjunction/connector-business-central": patch
---

BusinessCentral connector: `ResolveConfig` now recognizes the Dynamics 365 Business Central CredentialType's `azureClientId` / `azureClientSecret` / `azureTenantId` field keys, appended as fallbacks after the existing key names. A Credential authored against that CredentialType previously resolved to nothing and `ResolveConfig` threw "ClientId / ClientSecret not found".
