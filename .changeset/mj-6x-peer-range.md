---
'@memberjunction/connector-asana': patch
'@memberjunction/connector-bill-com': patch
'@memberjunction/connector-blackbaud': patch
'@memberjunction/connector-constant-contact': patch
'@memberjunction/connector-cvent': patch
'@memberjunction/connector-elevate': patch
'@memberjunction/connector-eventbrite': patch
'@memberjunction/connector-eventscribe': patch
'@memberjunction/connector-everhour': patch
'@memberjunction/connector-fonteva': patch
'@memberjunction/connector-ga4': patch
'@memberjunction/connector-growthzone': patch
'@memberjunction/connector-higher-logic-thrive-community': patch
'@memberjunction/connector-higher-logic-vanilla': patch
'@memberjunction/connector-hivebrite': patch
'@memberjunction/connector-hubspot': patch
'@memberjunction/connector-id-window-scan': patch
'@memberjunction/connector-imis': patch
'@memberjunction/connector-impexium': patch
'@memberjunction/connector-magnetmail': patch
'@memberjunction/connector-mailchimp': patch
'@memberjunction/connector-membersuite': patch
'@memberjunction/connector-microsoft-dynamics-365-dataverse': patch
'@memberjunction/connector-mongodb': patch
'@memberjunction/connector-mysql': patch
'@memberjunction/connector-neon-crm': patch
'@memberjunction/connector-netforum-enterprise': patch
'@memberjunction/connector-netsuite': patch
'@memberjunction/connector-nimble-ams': patch
'@memberjunction/connector-novi-ams': patch
'@memberjunction/connector-openwater': patch
'@memberjunction/connector-oracle': patch
'@memberjunction/connector-orcid': patch
'@memberjunction/connector-path-lms': patch
'@memberjunction/connector-pheedloop': patch
'@memberjunction/connector-postgresql': patch
'@memberjunction/connector-propfuel': patch
'@memberjunction/connector-quickbooks': patch
'@memberjunction/connector-rasa-io': patch
'@memberjunction/connector-reply': patch
'@memberjunction/connector-rhythm-software': patch
'@memberjunction/connector-salesforce': patch
'@memberjunction/connector-sharepoint': patch
'@memberjunction/connector-snowflake': patch
'@memberjunction/connector-sqlserver': patch
'@memberjunction/connector-stripe': patch
'@memberjunction/connector-totara': patch
'@memberjunction/connector-wild-apricot': patch
'@memberjunction/connector-wordpress': patch
'@memberjunction/connector-zendesk': patch
---

Allow MemberJunction 6.x as a peer. Every connector capped its `@memberjunction/*` peers at `<6.0.0`; the ceiling moves to `<7.0.0`, and `mj-app.json.mjVersionRange` moves with it so npm and `mjdev app register` agree. Floors are unchanged, so 5.x hosts are unaffected.

Why the ceiling is the fix on a 6.x host: pnpm's `auto-install-peers` satisfies an unmet peer range by installing a **second** copy of `@memberjunction/core`, and two copies of core in one process is the failure that surfaces as thousands of unrelated-looking type errors. Business Central hit exactly this and was widened alone (#180, then #208 for the manifest); this brings the other 56 connectors, the two private platform packages, and the shared `connector-id-window-scan` package to the same range, so the duplicate cannot return transitively through a shared dependency either. The scaffolding scripts (`new-connector`, `scaffold-openapps`, `split-into-packages`) now mint `<7.0.0` too, so a new connector does not reintroduce the cap.

Verified at compile time, not at runtime: all 61 packages in the repo (57 connectors, the two private platform packages, the two shared packages) type-check against `@memberjunction/*@6.1.0-edge.5` — the only 6.x published at the time; there is no stable 6.x yet — with every framework `.d.ts` resolved from the 6.x install and none from 5.x. That check is `npm run check:mj-compat` (`scripts/typecheck-against-mj.mjs`), added with this change so the claim can be re-run against any MJ version. It is API compatibility at the type level; the only runtime evidence on a 6.x host remains the Business Central team's edge deployment.
