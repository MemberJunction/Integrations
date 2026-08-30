# MJ WP Activity Log Bridge

A small, read-only WordPress plugin that exposes [WP Activity Log](https://wordpress.org/plugins/wp-security-audit-log/)
(WSAL) events over the WordPress REST API, so the MemberJunction WordPress connector can sync them
like any other collection.

It registers two GET routes and nothing else. No writes, no settings screen, no tables, no cron,
no outbound calls.

---

## Why this exists

WP Activity Log stores its events in two custom tables — `wsal_occurrences` and `wsal_metadata` —
and **registers no REST routes of its own**. Verified against WSAL 5.6.6: neither
`register_rest_route` nor `rest_api_init` appears anywhere in the plugin.

That matters because the MJ WordPress connector builds its object universe from the site's own REST
route index. A plugin that registers routes is discovered automatically; a plugin that registers
none is invisible, no matter what is in its database.

So the choice was between reaching around WordPress into MySQL directly, or giving the data the REST
surface it was missing. This is the second option. The connector needs **no code change at all** —
it already treats any GET collection route that registers `per_page` as a listable object, and does
not filter third-party namespaces.

---

## Requirements

| | |
|---|---|
| WordPress | 5.6+ (Application Passwords) |
| PHP | 7.4+ |
| WP Activity Log | 5.0+ (tested against 5.6.6) |
| Capability | `manage_options`, or `manage_network_options` on multisite |

Application Passwords require HTTPS. WordPress refuses them over plain HTTP unless the site's
environment type is `local`, so a production site must be served over TLS.

---

## Install

1. Copy the `mj-wsal-bridge` directory into `wp-content/plugins/`.
2. Activate it — **Plugins → MJ WP Activity Log Bridge**, or `wp plugin activate mj-wsal-bridge`.
3. Confirm the routes are live:

   ```bash
   curl -s https://example.org/wp-json/ | grep -o 'mj-wsal/v1'
   ```

4. Create an Application Password for the integration user
   (**Users → Profile → Application Passwords**) and give MJ the site URL, the username, and that
   password.

To verify a real install end to end:

```bash
WP_URL=https://example.org WP_USER=svc-memberjunction WP_APP_PASSWORD='xxxx xxxx xxxx xxxx xxxx xxxx' \
  node test/probe.mjs
```

The probe is read-only. It checks discovery, auth, bounded pagination, the incremental watermark,
payload shape, catalog join integrity, and the OPTIONS schema.

---

## Routes

### `GET /wp-json/mj-wsal/v1/events`

One row per logged event, with its metadata pivoted in.

| Param | Type | Notes |
|---|---|---|
| `page` | int | 1-based. |
| `per_page` | int | Default and maximum 100. Above the cap is **rejected**, not clamped. |
| `after` | string | ISO-8601 UTC datetime or Unix seconds. **Inclusive.** |
| `before` | string | ISO-8601 UTC datetime or Unix seconds. Exclusive. |
| `site_id` | int | Restrict to one multisite site. |

Responds with `X-WP-Total` and `X-WP-TotalPages`. Rows are ordered by `(created_on, id)`.

```jsonc
{
  "id": 88421,
  "site_id": 1,
  "alert_id": 1000,
  "alert_label": "User logged in",
  "created_on": 1788047786.884744,      // raw double, exactly as stored
  "created_at": "2026-08-29T23:56:26.884Z",
  "severity": "250",                     // raw numeric level
  "severity_label": "Low",
  "object": "user",
  "event_type": "login",
  "username": "jdoe",
  "user_id": 42,
  "user_roles": "administrator",
  "client_ip": "203.0.113.9",
  "user_agent": "Mozilla/5.0 …",
  "session_id": "…",
  "post_id": 0,
  "post_type": "",
  "post_status": "",
  "meta": { "CurrentUserRoles": "administrator", "LoginPageURL": "…" }
}
```

### `GET /wp-json/mj-wsal/v1/event-types`

The event-type catalog — every event ID the installed plugin set can emit, with label, severity,
category and subcategory. Around 467 rows on a stock WordPress + WooCommerce install. Read through
WSAL's own `Alert_Manager`, so events registered by third-party sensors (WooCommerce, Gravity Forms,
Yoast, …) are included automatically and labels track the installed version.

Join `ActivityLogEvent.alert_id` → `ActivityLogEventType.alert_id`.

---

## Three decisions worth knowing about

**`created_at` exists because a bare epoch is ambiguous.** WSAL stores `created_on` as a double in
*seconds*. Most date parsers — including MJ's — read a bare number as *milliseconds*, which would
date every event to January 1970. Rather than rely on every consumer guessing the unit correctly,
the bridge emits the same instant as an explicit ISO-8601 string and the connector watermarks on
that. `created_on` is still passed through untouched for anyone reconciling against the table.

**`after` is inclusive, on purpose.** `created_on` is not unique — several events routinely share a
timestamp, and `created_at` carries only milliseconds where the column has microseconds. An
exclusive bound would silently drop every event sharing the last synced timestamp. Inclusive means
the boundary event is occasionally re-delivered, which the consumer dedupes on `id`. Re-delivering
an event is free; losing one is unrecoverable.

**Serialised metadata is decoded without instantiating anything.** Some WSAL metadata values are
PHP-serialised objects. Unserialising them blindly is a known object-injection vector, so the bridge
unserialises with `allowed_classes => false` and then flattens the resulting inert placeholder to its
public properties. Real JSON out; no class ever constructed.

---

## Security

- **Read-only.** Only `GET` and `OPTIONS`. Nothing writes.
- **Admin-gated.** The activity log records usernames, IP addresses and content changes, so the
  routes require a full administrator rather than a lesser role. Override with the
  `mj_wsal_bridge_capability` filter if you maintain a dedicated integration role.
- **Parameterised SQL throughout.** Table names derive from `$wpdb->base_prefix`, never from input.
- **Multisite-correct.** WSAL keys its tables off `base_prefix` (one network-wide table set), so the
  bridge does too. Using the per-site `prefix` would read the wrong table, or none.

## Limits

- Reads what WP Activity Log retains. The plugin's own pruning (default 3 months when enabled)
  deletes history the bridge can no longer serve — set the sync cadence and retention accordingly.
- `meta` values are returned in full and are not truncated, so an event carrying a large value
  produces a large row. Lower `per_page` if a page ever gets unwieldy.
