---
"@memberjunction/connector-rasa-io": minor
---

rasa.io: per-person topics and sample queries. Two new objects read each newsletter's stored topic clouds (`/v2/insights/newsletter/{id}/topics`): Newsletter Contact Topic and Newsletter Contact Category, one row per newsletter, contact and topic (or category), with clicks, weight, first and last click and the week the cloud was built. `contact_id` is the cloud's `person_id`, which is the contact's rasa.io id, so each row joins to Contact for the email. A nested collection under a parent-scoped feed now gets its parent's id (`newsletter_id`) as well as its own parent key, and can carry other parent fields (`carryFields`). The connector also ships five approved queries in a `rasa.io` category that return the contact's email with topics, rolled-up interests, newsletter engagement and external IDs. Table and column descriptions now say that one contact id is shared across every table, and that how far back events go is set per account.
