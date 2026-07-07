---
"@memberjunction/connector-magnetmail": major
---

MagnetMail connector **v2.0.0** — a full rebuild of the deprecated v1 (breaking override). SOAP-over-`BaseRESTIntegrationConnector` for the `mmapi.asmx` API: two-step `<mmAuthHeader>` session auth, per-operation `ListOperation`/CRUD wiring across 47 objects (36 list ops + 7 write ops), `getMessagesUTC` incremental watermark, and full-record pass-through. Wires the never-shrink sample-union in `IntrospectSchema` (`@memberjunction/connector-schema-merge`) so tenant custom columns are captured, and bounds every string column with an explicit length. Credential type moved from the removed custom `MagnetMail API` to baseline `Basic Auth`. Verified with a full-lifecycle GENUINE-GREEN-MOCK e2e (forward sync, coverage over every object, delta CRUD, idempotent, custom-column capture, pagination, watermark, bidirectional writes) and 37 unit tests.
