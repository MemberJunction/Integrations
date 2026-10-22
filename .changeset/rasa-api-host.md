---
"@memberjunction/connector-rasa-io": patch
---

The rasa.io credential gains an optional **API host** field (`baseUrl`). Leave it blank for rasa.io production (`https://api.rasa.io`); set it to reach another rasa.io environment, e.g. `https://api-dev.rasa.io` for client credentials generated in rasa.io's dev dashboard, which production rejects. A host typed without a scheme gets `https://`. The connector already honored this key; the credential form just never showed it, so a connection made in MJ Central could only target production.
