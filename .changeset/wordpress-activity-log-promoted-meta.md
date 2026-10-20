---
"@memberjunction/connector-wordpress": minor
---

Give the Activity Log fields that matter their own columns.

`ActivityLogEvent.meta` holds every per-event detail WP Activity Log records, in one JSON object, so a member ID or the URL a member viewed lands in a single text column that every query has to parse. Six keys now also arrive as their own fields:

| Field | From | Notes |
| --- | --- | --- |
| `ams_id` | `meta.ams_id` | The member's AMS ID, when the site records one |
| `post_url` | `meta.PostUrl` | Query string and fragment removed, so it joins to a post's `link` |
| `post_url_full` | `meta.PostUrl` | As visited, query string kept (campaign attribution such as `utm_source`) |
| `post_title` | `meta.PostTitle` | |
| `post_date` | `meta.PostDate` | Site-local, as WP Activity Log records it |
| `editor_link` | `meta.EditorLinkPost` | |

HTML entities are decoded on the way in. WP Activity Log stores URLs through `esc_url`, so every `&` arrives as `&#038;`. Blank values land as null rather than an empty string. `meta` itself is unchanged, so no key is lost.

The mapping lives in metadata, not code: each field declares `Configuration.promoteFrom` (`"meta.PostUrl"`, plus `stripQuery` for the canonical URL), and the connector fills any field that declares it. Lengths are explicit (100 for `ams_id`, 2048 for the URLs, 1000 for the title), because an unsized string is capped at 255 and a row with a longer value is dropped. Real `PostUrl` values reach 263 characters once newsletter tracking is attached.

Delta migration `V202610151853` (+ its Postgres twin) adds the 6 IntegrationObjectField rows on top of the existing catalog, additively, taking `ActivityLogEvent` from 20 fields to 26.
