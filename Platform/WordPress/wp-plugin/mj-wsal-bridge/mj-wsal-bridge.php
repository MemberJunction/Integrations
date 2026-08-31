<?php
/**
 * Plugin Name: MJ WP Activity Log Bridge
 * Description: Exposes the WP Activity Log (WSAL) tables over the WordPress REST API, read-only, so the MemberJunction WordPress connector can discover and sync them like any other collection. Registers no writes and stores no data of its own.
 * Version:     1.1.0
 * Requires PHP: 7.4
 * Author:      MemberJunction
 * License:     GPL-2.0-or-later
 *
 * WHY THIS PLUGIN EXISTS
 * ----------------------
 * WP Activity Log keeps its events in two custom tables (`wsal_occurrences`, `wsal_metadata`) and
 * registers ZERO REST routes of its own — verified against WSAL 5.6.6: neither `register_rest_route`
 * nor `rest_api_init` appears anywhere in the plugin. So the data is invisible to `wp/v2` and
 * therefore invisible to the MJ WordPress connector, which builds its object universe from the
 * site's own route index.
 *
 * This bridge supplies the missing routes. The MJ connector then needs NO code change at all:
 *   - It derives candidate objects from the route index, and a route qualifies when it is a GET
 *     collection route that registers `per_page` — both routes below do.
 *   - Third-party namespaces are explicitly NOT filtered out by the connector.
 *   - A WordPress Application Password already authenticates every namespace, including this one.
 *   - The connector paginates on `X-WP-Total` / `X-WP-TotalPages`, which both routes emit.
 *
 * @package mj-wsal-bridge
 */

// Exit if accessed directly.
if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

if ( ! class_exists( 'MJ_WSAL_Bridge' ) ) {

	/**
	 * Read-only REST surface over the WP Activity Log tables.
	 */
	final class MJ_WSAL_Bridge {

		/** REST namespace. Deliberately vendor-prefixed so it can never collide with WSAL's own future routes. */
		const REST_NAMESPACE = 'mj-wsal/v1';

		/**
		 * Page-size ceiling. Matches the WordPress core convention (and the MJ connector's documented
		 * `per_page` cap) so the connector's clamp and ours agree; a larger request is REJECTED by the
		 * arg validator rather than silently clamped, exactly as core does.
		 */
		const MAX_PER_PAGE = 100;

		/**
		 * Boot.
		 */
		public static function init() {
			add_action( 'rest_api_init', array( __CLASS__, 'register_routes' ) );
		}

		/**
		 * Register both collection routes.
		 *
		 * Each registers `page` + `per_page`, which is precisely the discriminator the MJ connector uses
		 * to tell a listable record collection from an RPC endpoint.
		 */
		public static function register_routes() {
			register_rest_route(
				self::REST_NAMESPACE,
				'/events',
				array(
					array(
						'methods'             => WP_REST_Server::READABLE,
						'callback'            => array( __CLASS__, 'get_events' ),
						'permission_callback' => array( __CLASS__, 'permission_check' ),
						'args'                => self::get_events_collection_params(),
					),
					'schema' => array( __CLASS__, 'get_event_schema' ),
				)
			);

			// Introspection. Reports which WP Activity Log tables this site actually HAS, with their
			// columns and row counts. It exists because table presence is not a constant: the free
			// plugin creates only wsal_occurrences and wsal_metadata, while sessions, notifications and
			// the two report tables arrive with premium extensions — and their columns vary by version.
			// Deciding what to support by GUESSING which tables exist would be a guess about someone
			// else's install; this asks the site.
			register_rest_route(
				self::REST_NAMESPACE,
				'/tables',
				array(
					array(
						'methods'             => WP_REST_Server::READABLE,
						'callback'            => array( __CLASS__, 'get_tables' ),
						'permission_callback' => array( __CLASS__, 'permission_check' ),
						'args'                => array(),
					),
				)
			);

			// The remaining WP Activity Log tables, each behind the same generic handler. Registered
			// unconditionally so the route index is stable across sites; a site missing the table gets
			// a 503 naming it when the route is called, which is a far clearer signal than the route
			// silently not existing.
			foreach ( array_keys( self::generic_tables() ) as $mj_wsal_key ) {
				register_rest_route(
					self::REST_NAMESPACE,
					'/' . $mj_wsal_key,
					array(
						array(
							'methods'             => WP_REST_Server::READABLE,
							'callback'            => static function ( WP_REST_Request $request ) use ( $mj_wsal_key ) {
								return self::get_generic( $mj_wsal_key, $request );
							},
							'permission_callback' => array( __CLASS__, 'permission_check' ),
							'args'                => self::get_basic_collection_params(),
						),
						'schema' => static function () use ( $mj_wsal_key ) {
							return self::generic_schema( $mj_wsal_key );
						},
					)
				);
			}

			register_rest_route(
				self::REST_NAMESPACE,
				'/event-types',
				array(
					array(
						'methods'             => WP_REST_Server::READABLE,
						'callback'            => array( __CLASS__, 'get_event_types' ),
						'permission_callback' => array( __CLASS__, 'permission_check' ),
						'args'                => self::get_basic_collection_params(),
					),
					'schema' => array( __CLASS__, 'get_event_type_schema' ),
				)
			);
		}

		// ─── Auth ────────────────────────────────────────────────────────────────

		/**
		 * Who may read the activity log.
		 *
		 * The activity log is sensitive — it records usernames, IPs and content changes — so this
		 * deliberately requires a full administrator rather than a lesser role. On multisite the tables
		 * are network-wide (WSAL keys them off `base_prefix`), so a network capability is required there.
		 *
		 * Filterable via `mj_wsal_bridge_capability` for sites that maintain a dedicated integration role.
		 *
		 * @return true|WP_Error
		 */
		public static function permission_check() {
			$capability = is_multisite() ? 'manage_network_options' : 'manage_options';

			/**
			 * Filters the capability required to read the bridge routes.
			 *
			 * @param string $capability Capability name.
			 */
			$capability = apply_filters( 'mj_wsal_bridge_capability', $capability );

			if ( ! current_user_can( $capability ) ) {
				return new WP_Error(
					'mj_wsal_forbidden',
					__( 'You are not allowed to read the activity log.', 'mj-wsal-bridge' ),
					array( 'status' => rest_authorization_required_code() )
				);
			}

			return true;
		}

		// ─── Tables ──────────────────────────────────────────────────────────────

		/**
		 * WSAL stores ONE network-wide table set keyed off `base_prefix`, not the per-site `prefix`
		 * (see WSAL's Abstract_Entity::get_table_name). Using `prefix` here would silently read the
		 * wrong table — or nothing at all — on a multisite subsite.
		 *
		 * @param string $suffix Table suffix, e.g. 'wsal_occurrences'.
		 * @return string Fully-qualified table name.
		 */
		private static function table( $suffix ) {
			global $wpdb;
			return $wpdb->base_prefix . $suffix;
		}

		/**
		 * Whether the WSAL tables are actually present.
		 *
		 * @return bool
		 */
		private static function tables_exist() {
			global $wpdb;

			foreach ( array( 'wsal_occurrences', 'wsal_metadata' ) as $suffix ) {
				$table = self::table( $suffix );
				// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- table name is derived from $wpdb->base_prefix, not user input.
				$found = $wpdb->get_var( $wpdb->prepare( 'SHOW TABLES LIKE %s', $table ) );
				if ( $found !== $table ) {
					return false;
				}
			}

			return true;
		}

		/**
		 * Uniform "WSAL isn't here" response.
		 *
		 * @return WP_Error
		 */
		private static function missing_tables_error() {
			return new WP_Error(
				'mj_wsal_tables_missing',
				__( 'The WP Activity Log tables were not found on this site. Install and activate WP Activity Log before using this bridge.', 'mj-wsal-bridge' ),
				array( 'status' => 503 )
			);
		}

		// ─── /events ─────────────────────────────────────────────────────────────

		/**
		 * Collection params for /events.
		 *
		 * @return array
		 */
		private static function get_events_collection_params() {
			return array_merge(
				self::get_basic_collection_params(),
				array(
					'after'   => array(
						'description'       => __( 'Return events at or after this point. Accepts an ISO-8601 UTC datetime or a Unix timestamp in seconds. INCLUSIVE — see the note on watermark semantics.', 'mj-wsal-bridge' ),
						'type'              => 'string',
						'required'          => false,
						'validate_callback' => array( __CLASS__, 'validate_timestamp_arg' ),
					),
					'before'  => array(
						'description'       => __( 'Return events strictly before this point. Accepts an ISO-8601 UTC datetime or a Unix timestamp in seconds. EXCLUSIVE.', 'mj-wsal-bridge' ),
						'type'              => 'string',
						'required'          => false,
						'validate_callback' => array( __CLASS__, 'validate_timestamp_arg' ),
					),
					'site_id' => array(
						'description' => __( 'Restrict to one multisite site ID.', 'mj-wsal-bridge' ),
						'type'        => 'integer',
						'required'    => false,
					),
				)
			);
		}

		/**
		 * The `page` / `per_page` pair every listable collection must register.
		 *
		 * @return array
		 */
		private static function get_basic_collection_params() {
			// `validate_callback` is REQUIRED, not decorative: WordPress only enforces minimum/maximum when
			// an arg declares one. Without it `maximum` is silently ignored, per_page=5000 sanitizes
			// straight through absint into the LIMIT, and a route advertised as bounded turns into an
			// unbounded read on a large tenant. Core's own get_collection_params() sets it for this reason.
			return array(
				'page'     => array(
					'description'       => __( 'Current page of the collection.', 'mj-wsal-bridge' ),
					'type'              => 'integer',
					'default'           => 1,
					'minimum'           => 1,
					'sanitize_callback' => 'absint',
					'validate_callback' => 'rest_validate_request_arg',
				),
				'per_page' => array(
					'description'       => __( 'Maximum number of items to return per page.', 'mj-wsal-bridge' ),
					'type'              => 'integer',
					'default'           => self::MAX_PER_PAGE,
					'minimum'           => 1,
					'maximum'           => self::MAX_PER_PAGE,
					'sanitize_callback' => 'absint',
					'validate_callback' => 'rest_validate_request_arg',
				),
			);
		}

		/**
		 * Accept either an ISO-8601 datetime or a numeric epoch.
		 *
		 * @param mixed $value Raw arg value.
		 * @return true|WP_Error
		 */
		public static function validate_timestamp_arg( $value ) {
			if ( null === self::to_epoch( $value ) ) {
				return new WP_Error(
					'mj_wsal_bad_timestamp',
					__( 'Expected an ISO-8601 datetime or a Unix timestamp in seconds.', 'mj-wsal-bridge' ),
					array( 'status' => 400 )
				);
			}

			return true;
		}

		/**
		 * Coerce an ISO-8601 string or numeric epoch into a float epoch (seconds).
		 *
		 * Sub-second precision is FLOORED, never rounded. `created_on` is a double with microsecond
		 * precision but the ISO form we emit carries only milliseconds, so rounding up could advance the
		 * watermark past an event that was never delivered. Flooring can only ever re-deliver a boundary
		 * event, which the consumer dedupes on `id`. Losing an event is unrecoverable; repeating one is free.
		 *
		 * @param mixed $value ISO-8601 string, numeric string, or number.
		 * @return float|null Epoch seconds, or null when unparseable.
		 */
		private static function to_epoch( $value ) {
			if ( is_int( $value ) || is_float( $value ) ) {
				return (float) $value;
			}

			if ( ! is_string( $value ) || '' === trim( $value ) ) {
				return null;
			}

			$value = trim( $value );

			if ( is_numeric( $value ) ) {
				return (float) $value;
			}

			// A zoneless ISO string is interpreted as UTC, matching how the MJ side parses it.
			$normalized = $value;
			if ( ! preg_match( '/(Z|[+-]\d{2}:?\d{2})$/i', $normalized ) ) {
				$normalized .= 'Z';
			}

			try {
				$dt = new DateTimeImmutable( $normalized );
			} catch ( Exception $e ) {
				return null;
			}

			// Floor to the millisecond the ISO form can actually express.
			return (float) $dt->format( 'U' ) + ( (int) $dt->format( 'v' ) ) / 1000;
		}

		/**
		 * GET /mj-wsal/v1/events
		 *
		 * @param WP_REST_Request $request Request.
		 * @return WP_REST_Response|WP_Error
		 */
		public static function get_events( WP_REST_Request $request ) {
			global $wpdb;

			if ( ! self::tables_exist() ) {
				return self::missing_tables_error();
			}

			$occurrences = self::table( 'wsal_occurrences' );
			$per_page    = (int) $request->get_param( 'per_page' );
			$page        = (int) $request->get_param( 'page' );
			$offset      = ( $page - 1 ) * $per_page;

			// ── WHERE ──
			$where  = array( '1=1' );
			$params = array();

			$after = $request->get_param( 'after' );
			if ( null !== $after && '' !== $after ) {
				// INCLUSIVE (>=). `created_on` is not unique — several events can share a timestamp —
				// so an exclusive bound would drop every co-timestamped sibling of the last row synced.
				$where[]  = 'created_on >= %f';
				$params[] = self::to_epoch( $after );
			}

			$before = $request->get_param( 'before' );
			if ( null !== $before && '' !== $before ) {
				$where[]  = 'created_on < %f';
				$params[] = self::to_epoch( $before );
			}

			$site_id = $request->get_param( 'site_id' );
			if ( null !== $site_id && '' !== $site_id ) {
				$where[]  = 'site_id = %d';
				$params[] = (int) $site_id;
			}

			$where_sql = implode( ' AND ', $where );

			// ── Total (a separate COUNT; SQL_CALC_FOUND_ROWS is deprecated as of MySQL 8.0.17) ──
			// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- table name from base_prefix; all values are placeholders.
			$count_sql = "SELECT COUNT(*) FROM `{$occurrences}` WHERE {$where_sql}";
			$total     = (int) ( $params
				// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
				? $wpdb->get_var( $wpdb->prepare( $count_sql, $params ) )
				// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
				: $wpdb->get_var( $count_sql ) );

			// ── Page ──
			// ORDER BY (created_on, id) is a TOTAL order. Ordering on created_on alone is not stable —
			// co-timestamped rows could shuffle between pages and be skipped or duplicated across an
			// offset boundary. The trailing `id` breaks every tie deterministically.
			// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- table name from base_prefix; all values are placeholders.
			$rows_sql = "SELECT * FROM `{$occurrences}` WHERE {$where_sql} ORDER BY created_on ASC, id ASC LIMIT %d OFFSET %d";
			$rows     = $wpdb->get_results(
				// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
				$wpdb->prepare( $rows_sql, array_merge( $params, array( $per_page, $offset ) ) ),
				ARRAY_A
			);

			if ( ! is_array( $rows ) ) {
				$rows = array();
			}

			$meta_by_occurrence = self::fetch_metadata( wp_list_pluck( $rows, 'id' ) );
			$catalog            = self::get_alert_catalog();

			$data = array();
			foreach ( $rows as $row ) {
				$data[] = self::shape_event( $row, $meta_by_occurrence, $catalog );
			}

			$response = new WP_REST_Response( $data );

			// The MJ connector terminates paging on these headers, exactly as it does for wp/v2.
			$response->header( 'X-WP-Total', (string) $total );
			$response->header( 'X-WP-TotalPages', (string) ( $per_page > 0 ? (int) ceil( $total / $per_page ) : 0 ) );

			return $response;
		}

		/**
		 * Pivot `wsal_metadata` for a page of occurrences.
		 *
		 * ONE query for the whole page, never one per row — the metadata table carries several rows per
		 * event and an N+1 here would multiply a 100-row page into 100 round trips.
		 *
		 * @param int[] $occurrence_ids Occurrence IDs on this page.
		 * @return array<int,array<string,mixed>> occurrence_id => [ name => value ].
		 */
		private static function fetch_metadata( array $occurrence_ids ) {
			global $wpdb;

			$occurrence_ids = array_values( array_filter( array_map( 'intval', $occurrence_ids ) ) );
			if ( empty( $occurrence_ids ) ) {
				return array();
			}

			$metadata     = self::table( 'wsal_metadata' );
			$placeholders = implode( ',', array_fill( 0, count( $occurrence_ids ), '%d' ) );

			// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- table name from base_prefix; IDs are placeholders.
			$sql = "SELECT occurrence_id, name, value FROM `{$metadata}` WHERE occurrence_id IN ({$placeholders})";

			// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
			$rows = $wpdb->get_results( $wpdb->prepare( $sql, $occurrence_ids ), ARRAY_A );

			$out = array();
			foreach ( (array) $rows as $row ) {
				$out[ (int) $row['occurrence_id'] ][ $row['name'] ] = self::decode_meta_value( $row['value'] );
			}

			return $out;
		}

		/**
		 * WSAL serialises non-scalar metadata values with PHP `serialize()`, and some of them are OBJECTS
		 * (`PluginData` is a serialised stdClass). Unserialising blindly is a known object-injection
		 * vector, so this permits NO classes: a serialised object comes back as __PHP_Incomplete_Class,
		 * which is inert — no constructor, no __wakeup, no autoload.
		 *
		 * Rather than give up there and emit an opaque `O:8:"stdClass":6:{…}` string, the incomplete
		 * object is flattened to its public properties. That yields real structured JSON with no class
		 * ever instantiated. The private marker key PHP injects is dropped on the way out.
		 *
		 * @param string $value Raw stored value.
		 * @return mixed
		 */
		private static function decode_meta_value( $value ) {
			if ( ! is_string( $value ) || ! is_serialized( $value ) ) {
				return $value;
			}

			$decoded = @unserialize( $value, array( 'allowed_classes' => false ) ); // phpcs:ignore WordPress.PHP.NoSilencedErrors.Discouraged

			if ( false === $decoded && 'b:0;' !== $value ) {
				return $value; // Genuinely undecodable — hand back what was stored.
			}

			return self::flatten_incomplete( $decoded );
		}

		/**
		 * Recursively convert __PHP_Incomplete_Class placeholders into plain arrays.
		 *
		 * @param mixed $value Decoded value.
		 * @return mixed
		 */
		private static function flatten_incomplete( $value ) {
			if ( is_object( $value ) ) {
				$value = (array) $value;
				// PHP records the original class name under a mangled key; it is not data.
				unset( $value['__PHP_Incomplete_Class_Name'] );
				foreach ( array_keys( $value ) as $k ) {
					if ( is_string( $k ) && "\0" === substr( $k, 0, 1 ) ) {
						unset( $value[ $k ] ); // Private/protected property mangling — not public data.
					}
				}
			}

			if ( is_array( $value ) ) {
				foreach ( $value as $k => $v ) {
					$value[ $k ] = self::flatten_incomplete( $v );
				}
			}

			return $value;
		}

		/**
		 * Shape one occurrence row into the flattened event payload.
		 *
		 * @param array $row                One `wsal_occurrences` row.
		 * @param array $meta_by_occurrence Pivoted metadata for the page.
		 * @param array $catalog            alert_id => definition.
		 * @return array
		 */
		private static function shape_event( array $row, array $meta_by_occurrence, array $catalog ) {
			$id         = (int) $row['id'];
			$alert_id   = (int) $row['alert_id'];
			$created_on = (float) $row['created_on'];
			$definition = isset( $catalog[ $alert_id ] ) ? $catalog[ $alert_id ] : null;

			return array(
				'id'          => $id,
				'site_id'     => (int) $row['site_id'],
				'alert_id'    => $alert_id,
				'alert_label' => $definition ? $definition['label'] : '',
				// The raw double, preserved exactly as stored, for anyone reconciling against the table.
				'created_on'  => $created_on,
				// The SAME instant as ISO-8601 UTC. This is the field the MJ connector watermarks on:
				// a bare epoch NUMBER is ambiguous to date parsers (seconds vs milliseconds), and reading
				// these seconds as milliseconds would place every event in January 1970. An explicit ISO
				// string removes the ambiguity at the source instead of relying on the consumer to guess.
				'created_at'  => self::to_iso8601( $created_on ),
				// The raw code as stored — the occurrences table holds a NUMERIC level (500/400/300/250/200),
				// not the WSAL_* constant name.
				'severity'       => (string) $row['severity'],
				'severity_label' => self::severity_label( $row['severity'] ),
				'object'      => (string) $row['object'],
				'event_type'  => (string) $row['event_type'],
				'username'    => null === $row['username'] ? '' : (string) $row['username'],
				'user_id'     => null === $row['user_id'] ? null : (int) $row['user_id'],
				'user_roles'  => (string) $row['user_roles'],
				'client_ip'   => (string) $row['client_ip'],
				'user_agent'  => (string) $row['user_agent'],
				'session_id'  => (string) $row['session_id'],
				'post_id'     => (int) $row['post_id'],
				'post_type'   => (string) $row['post_type'],
				'post_status' => (string) $row['post_status'],
				'meta'        => isset( $meta_by_occurrence[ $id ] ) ? $meta_by_occurrence[ $id ] : new stdClass(),
			);
		}

		/**
		 * Resolve the stored numeric severity level into a readable label.
		 *
		 * The occurrences table stores a numeric level, not a name: 500/400/300/250/200. Left raw, every
		 * consumer would have to hard-code that five-way mapping. Resolved through the plugin's own
		 * Constants::WSAL_SEVERITIES so the mapping tracks the installed version rather than a copy of it
		 * that silently rots; falls back to the documented levels when the class is unavailable.
		 *
		 * @param mixed $code Stored severity value.
		 * @return string 'Critical' | 'High' | 'Medium' | 'Low' | 'Informational' | 'Unknown' | ''.
		 */
		private static function severity_label( $code ) {
			if ( null === $code || '' === $code ) {
				return '';
			}

			$map = array( 500 => 'WSAL_CRITICAL', 400 => 'WSAL_HIGH', 300 => 'WSAL_MEDIUM', 250 => 'WSAL_LOW', 200 => 'WSAL_INFORMATIONAL', 0 => 'E_UNKNOWN' );
			if ( class_exists( '\WSAL\Controllers\Constants' ) && defined( '\WSAL\Controllers\Constants::WSAL_SEVERITIES' ) ) {
				$map = \WSAL\Controllers\Constants::WSAL_SEVERITIES;
			}

			$key = (int) $code;
			if ( ! isset( $map[ $key ] ) ) {
				return 'Unknown';
			}

			// 'WSAL_CRITICAL' → 'Critical'; 'E_UNKNOWN' → 'Unknown'.
			$name = preg_replace( '/^(WSAL|E)_/', '', $map[ $key ] );

			return ucfirst( strtolower( $name ) );
		}

		/**
		 * Epoch seconds → ISO-8601 UTC with milliseconds.
		 *
		 * @param float $epoch Epoch seconds.
		 * @return string
		 */
		private static function to_iso8601( $epoch ) {
			$seconds      = (int) floor( $epoch );
			$milliseconds = (int) floor( ( $epoch - $seconds ) * 1000 );

			return gmdate( 'Y-m-d\TH:i:s', $seconds ) . sprintf( '.%03dZ', $milliseconds );
		}

		// ─── /event-types ────────────────────────────────────────────────────────

		/**
		 * The alert catalog: WSAL's own event definitions, keyed by alert ID.
		 *
		 * Read through WSAL's public Alert_Manager rather than by re-parsing `defaults.php`, so
		 * third-party sensors (WooCommerce, Gravity Forms, Yoast, …) that register their own events are
		 * included automatically and the labels track the installed version.
		 *
		 * @return array<int,array<string,string>>
		 */
		private static function get_alert_catalog() {
			static $cache = null;

			if ( null !== $cache ) {
				return $cache;
			}

			$cache = array();

			if ( ! class_exists( '\WSAL\Controllers\Alert_Manager' ) ) {
				return $cache;
			}

			$alerts = \WSAL\Controllers\Alert_Manager::get_alerts();

			foreach ( (array) $alerts as $code => $alert ) {
				if ( ! is_array( $alert ) ) {
					continue;
				}

				$cache[ (int) $code ] = array(
					'alert_id'    => (int) $code,
					'label'       => isset( $alert['desc'] ) ? (string) $alert['desc'] : '',
					'message'     => isset( $alert['message'] ) ? (string) $alert['message'] : '',
					'severity'    => isset( $alert['severity'] ) ? (string) $alert['severity'] : '',
					'category'    => isset( $alert['category'] ) ? (string) $alert['category'] : '',
					'subcategory' => isset( $alert['subcategory'] ) ? (string) $alert['subcategory'] : '',
					'object'      => isset( $alert['object'] ) ? (string) $alert['object'] : '',
					'event_type'  => isset( $alert['event_type'] ) ? (string) $alert['event_type'] : '',
				);
			}

			ksort( $cache );

			return $cache;
		}

		/**
		 * GET /mj-wsal/v1/event-types
		 *
		 * A small, slow-moving dimension table — every event ID the installed plugin set can emit, with
		 * its human label, severity and category. Lets `alert_id` be interpreted without hard-coding a
		 * lookup on the consuming side.
		 *
		 * @param WP_REST_Request $request Request.
		 * @return WP_REST_Response
		 */
		public static function get_event_types( WP_REST_Request $request ) {
			$catalog  = array_values( self::get_alert_catalog() );
			$per_page = (int) $request->get_param( 'per_page' );
			$page     = (int) $request->get_param( 'page' );
			$total    = count( $catalog );

			$response = new WP_REST_Response( array_slice( $catalog, ( $page - 1 ) * $per_page, $per_page ) );
			$response->header( 'X-WP-Total', (string) $total );
			$response->header( 'X-WP-TotalPages', (string) ( $per_page > 0 ? (int) ceil( $total / $per_page ) : 0 ) );

			return $response;
		}


		// ─── /tables (introspection) ──────────────────────────────────────────────

		/**
		 * GET /mj-wsal/v1/tables
		 *
		 * Every `<base_prefix>wsal_*` table on this site, with its columns, types and row count.
		 *
		 * Discovered by PREFIX rather than from a fixed list, so a table this build has never heard of
		 * — a newer premium extension, a future version — still shows up instead of being invisible.
		 * Reports structure and counts only: no row content is read, so nothing in the activity log
		 * itself can leak through this route.
		 *
		 * @param WP_REST_Request $request Request.
		 * @return WP_REST_Response|WP_Error
		 */
		public static function get_tables( WP_REST_Request $request ) {
			global $wpdb;

			$prefix = $wpdb->base_prefix . 'wsal_';
			// LIKE pattern: esc_like then the wildcard, so an underscore in the prefix stays literal.
			$like = $wpdb->esc_like( $prefix ) . '%';

			// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- schema name and pattern are placeholders.
			$names = $wpdb->get_col(
				$wpdb->prepare(
					'SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = %s AND TABLE_NAME LIKE %s ORDER BY TABLE_NAME',
					DB_NAME,
					$like
				)
			);

			$known = array(
				'wsal_occurrences'          => 'Activity events. Supported today as ActivityLogEvent.',
				'wsal_metadata'             => 'Per-event name/value detail. Supported today, pivoted into ActivityLogEvent.meta.',
				'wsal_sessions'             => 'Live logged-in sessions. Rows are DELETED on logout, so this is a snapshot, not a history.',
				'wsal_custom_notifications' => 'Notification rules. Plugin configuration, not user activity.',
				'wsal_generated_reports'    => 'History of report runs. Plugin configuration, not user activity.',
				'wsal_periodic_reports'     => 'Scheduled report definitions. Plugin configuration, not user activity.',
			);

			$out = array();
			foreach ( (array) $names as $full ) {
				$suffix = substr( $full, strlen( $wpdb->base_prefix ) );

				// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- values are placeholders.
				$cols = $wpdb->get_results(
					$wpdb->prepare(
						'SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_KEY FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s ORDER BY ORDINAL_POSITION',
						DB_NAME,
						$full
					),
					ARRAY_A
				);

				// Table identifiers cannot be parameterised; this one came from information_schema for
				// this exact schema and prefix, never from input, and is backtick-quoted.
				$safe = str_replace( '`', '', $full );
				// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
				$rows = (int) $wpdb->get_var( "SELECT COUNT(*) FROM `{$safe}`" );

				$out[] = array(
					'table'     => $full,
					'suffix'    => $suffix,
					'rows'      => $rows,
					'supported' => in_array( $suffix, array( 'wsal_occurrences', 'wsal_metadata' ), true ),
					'note'      => isset( $known[ $suffix ] ) ? $known[ $suffix ] : 'Not documented by this build — discovered by prefix.',
					'columns'   => array_map(
						static function ( $c ) {
							return array(
								'name'     => $c['COLUMN_NAME'],
								'type'     => $c['COLUMN_TYPE'],
								'nullable' => 'YES' === $c['IS_NULLABLE'],
								'key'      => $c['COLUMN_KEY'],
							);
						},
						(array) $cols
					),
				);
			}

			// Name the documented tables that are ABSENT. Silence about a missing table reads as "we
			// looked and it was empty", which is a different fact from "this site never had it".
			$present = wp_list_pluck( $out, 'suffix' );
			$missing = array();
			foreach ( $known as $suffix => $note ) {
				if ( ! in_array( $suffix, $present, true ) ) {
					$missing[] = array( 'suffix' => $suffix, 'note' => $note );
				}
			}

			return new WP_REST_Response(
				array(
					'base_prefix' => $wpdb->base_prefix,
					'present'     => $out,
					'missing'     => $missing,
				)
			);
		}


		/**
		 * The remaining WP Activity Log tables, served by ONE generic handler.
		 *
		 * These four are not created by the free plugin — they arrive with premium extensions — so every
		 * route below is PRESENCE-GATED: a site without the table gets a clear 503 naming it, never a
		 * 500 and never an empty-but-successful page that reads as "there is no activity".
		 *
		 * `epoch` names columns holding a Unix timestamp; each gains an `<name>_at` ISO-8601 sibling,
		 * for the same reason ActivityLogEvent has `created_at`: a bare epoch is ambiguous to date
		 * parsers, and seconds read as milliseconds land every row in 1970.
		 *
		 * `json` names columns holding a JSON document in a text column. They are decoded so a consumer
		 * receives a real object rather than a string it has to parse a second time.
		 */
		private static function generic_tables() {
			return array(
				'sessions'          => array(
					'suffix' => 'wsal_sessions',
					'pk'     => 'id',
					'epoch'  => array( 'created_on', 'expires_on' ),
					'json'   => array(),
					'title'  => 'mj_wsal_session',
					'note'   => 'Live logged-in sessions. Rows are DELETED on logout, so this is a snapshot of who is signed in now, never a history.',
				),
				'notifications'     => array(
					'suffix' => 'wsal_custom_notifications',
					'pk'     => 'id',
					'epoch'  => array( 'created_on' ),
					'json'   => array( 'notification_settings', 'notification_template', 'notification_sms_template', 'notification_slack_template', 'notification_query' ),
					'title'  => 'mj_wsal_notification',
					'note'   => 'Notification rules configured in the plugin.',
				),
				'generated-reports' => array(
					'suffix' => 'wsal_generated_reports',
					'pk'     => 'id',
					'epoch'  => array( 'created_on' ),
					'json'   => array( 'generated_report_filters', 'generated_report_filters_normalized', 'generated_report_header_columns' ),
					'title'  => 'mj_wsal_generated_report',
					'note'   => 'History of report runs.',
				),
				'periodic-reports'  => array(
					'suffix' => 'wsal_periodic_reports',
					'pk'     => 'id',
					'epoch'  => array( 'created_on', 'last_sent' ),
					'json'   => array( 'report_data' ),
					'title'  => 'mj_wsal_periodic_report',
					'note'   => 'Scheduled report definitions.',
				),
			);
		}

		/**
		 * Columns of one table, from information_schema. Returns an empty array when the table is absent.
		 *
		 * @param string $full Fully-qualified table name.
		 * @return array<int,array<string,string>>
		 */
		private static function columns_of( $full ) {
			global $wpdb;
			// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- values are placeholders.
			return (array) $wpdb->get_results(
				$wpdb->prepare(
					'SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_KEY FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s ORDER BY ORDINAL_POSITION',
					DB_NAME,
					$full
				),
				ARRAY_A
			);
		}

		/**
		 * One page of a generic table.
		 *
		 * @param string          $key     Key into {@see generic_tables()}.
		 * @param WP_REST_Request $request Request.
		 * @return WP_REST_Response|WP_Error
		 */
		private static function get_generic( $key, WP_REST_Request $request ) {
			global $wpdb;

			$spec  = self::generic_tables()[ $key ];
			$full  = self::table( $spec['suffix'] );
			$cols  = self::columns_of( $full );

			if ( empty( $cols ) ) {
				return new WP_Error(
					'mj_wsal_table_missing',
					sprintf(
						/* translators: %s: database table name */
						__( 'The table "%s" does not exist on this site. It is created by a WP Activity Log premium extension; without that extension there is nothing to read here.', 'mj-wsal-bridge' ),
						$full
					),
					array( 'status' => 503 )
				);
			}

			$per_page = (int) $request->get_param( 'per_page' );
			$page     = (int) $request->get_param( 'page' );
			$pk       = $spec['pk'];

			// The PK comes from this file, never from input, and is validated against the real column
			// list before it reaches SQL — so an ordering clause can never be attacker-controlled.
			$names = wp_list_pluck( $cols, 'COLUMN_NAME' );
			$order = in_array( $pk, $names, true ) ? $pk : $names[0];

			$safe = str_replace( '`', '', $full );
			// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- identifier from information_schema, values are placeholders.
			$total = (int) $wpdb->get_var( "SELECT COUNT(*) FROM `{$safe}`" );
			// phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
			$rows = $wpdb->get_results(
				$wpdb->prepare( "SELECT * FROM `{$safe}` ORDER BY `{$order}` ASC LIMIT %d OFFSET %d", $per_page, ( $page - 1 ) * $per_page ),
				ARRAY_A
			);

			$data = array();
			foreach ( (array) $rows as $row ) {
				foreach ( $spec['json'] as $col ) {
					if ( isset( $row[ $col ] ) && is_string( $row[ $col ] ) && '' !== $row[ $col ] ) {
						$decoded = json_decode( $row[ $col ], true );
						if ( JSON_ERROR_NONE === json_last_error() ) {
							$row[ $col ] = $decoded;
						}
					}
				}
				foreach ( $spec['epoch'] as $col ) {
					if ( isset( $row[ $col ] ) && is_numeric( $row[ $col ] ) && (float) $row[ $col ] > 0 ) {
						$row[ $col . '_at' ] = self::to_iso8601( (float) $row[ $col ] );
					} elseif ( array_key_exists( $col, $row ) ) {
						$row[ $col . '_at' ] = null;   // 0 means "never", which is not 1970.
					}
				}
				$data[] = $row;
			}

			$response = new WP_REST_Response( $data );
			$response->header( 'X-WP-Total', (string) $total );
			$response->header( 'X-WP-TotalPages', (string) ( $per_page > 0 ? (int) ceil( $total / $per_page ) : 0 ) );

			return $response;
		}

		/**
		 * JSON Schema for a generic table, derived from the LIVE columns rather than a frozen list —
		 * these tables' shapes vary by premium version, so a hardcoded schema would misdescribe some
		 * sites. Absent table: an empty property set, and the route reports 503 when actually called.
		 *
		 * @param string $key Key into {@see generic_tables()}.
		 * @return array
		 */
		private static function generic_schema( $key ) {
			$spec  = self::generic_tables()[ $key ];
			$cols  = self::columns_of( self::table( $spec['suffix'] ) );
			$props = array();

			foreach ( $cols as $c ) {
				$props[ $c['COLUMN_NAME'] ] = array(
					'description' => $c['COLUMN_NAME'] . ' (' . $c['DATA_TYPE'] . ')',
					'type'        => self::json_type_for( $c['DATA_TYPE'], in_array( $c['COLUMN_NAME'], $spec['json'], true ) ),
					'readonly'    => true,
				);
			}
			foreach ( $spec['epoch'] as $col ) {
				if ( isset( $props[ $col ] ) ) {
					$props[ $col . '_at' ] = array(
						'description' => $col . ' as an ISO-8601 UTC datetime; null when unset.',
						'type'        => array( 'string', 'null' ),
						'format'      => 'date-time',
						'readonly'    => true,
					);
				}
			}

			return array(
				'$schema'    => 'http://json-schema.org/draft-04/schema#',
				'title'      => $spec['title'],
				'type'       => 'object',
				'properties' => $props,
			);
		}

		/**
		 * MySQL data type to JSON Schema type.
		 *
		 * @param string $data_type MySQL DATA_TYPE.
		 * @param bool   $is_json   Whether this build decodes the column as JSON.
		 * @return string|array
		 */
		private static function json_type_for( $data_type, $is_json ) {
			if ( $is_json ) {
				return array( 'object', 'array', 'string', 'null' );
			}
			switch ( strtolower( $data_type ) ) {
				case 'tinyint':
				case 'smallint':
				case 'mediumint':
				case 'int':
				case 'integer':
				case 'bigint':
					return array( 'integer', 'null' );
				case 'decimal':
				case 'float':
				case 'double':
					return array( 'number', 'null' );
				default:
					return array( 'string', 'null' );
			}
		}

		// ─── Schemas (what OPTIONS returns, and what the connector reads fields from) ──

		/**
		 * @return array
		 */
		public static function get_event_schema() {
			return array(
				'$schema'    => 'http://json-schema.org/draft-04/schema#',
				'title'      => 'mj_wsal_event',
				'type'       => 'object',
				'properties' => array(
					'id'          => array( 'description' => __( 'Unique event identifier.', 'mj-wsal-bridge' ), 'type' => 'integer', 'readonly' => true ),
					'site_id'     => array( 'description' => __( 'Multisite network site ID (1 on a single site).', 'mj-wsal-bridge' ), 'type' => 'integer', 'readonly' => true ),
					'alert_id'    => array( 'description' => __( 'WP Activity Log event type ID.', 'mj-wsal-bridge' ), 'type' => 'integer', 'readonly' => true ),
					'alert_label' => array( 'description' => __( 'Human-readable name of the event type.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'created_on'  => array( 'description' => __( 'Raw Unix timestamp in seconds, as stored.', 'mj-wsal-bridge' ), 'type' => 'number', 'readonly' => true ),
					'created_at'  => array( 'description' => __( 'The same instant as an ISO-8601 UTC datetime.', 'mj-wsal-bridge' ), 'type' => 'string', 'format' => 'date-time', 'readonly' => true ),
					'severity'       => array( 'description' => __( 'Raw numeric severity level as stored: 500, 400, 300, 250 or 200.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'severity_label' => array( 'description' => __( 'Severity resolved to a name: Critical, High, Medium, Low, Informational or Unknown.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'object'      => array( 'description' => __( 'Subject of the activity, e.g. user or post.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'event_type'  => array( 'description' => __( 'Classification of the activity, e.g. login or modified.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'username'    => array( 'description' => __( 'WordPress username responsible for the event.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'user_id'     => array( 'description' => __( 'WordPress user ID responsible for the event.', 'mj-wsal-bridge' ), 'type' => array( 'integer', 'null' ), 'readonly' => true ),
					'user_roles'  => array( 'description' => __( 'Roles held by the user at the time of the event.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'client_ip'   => array( 'description' => __( 'Source IP address.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'user_agent'  => array( 'description' => __( 'Browser user agent string.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'session_id'  => array( 'description' => __( 'Session the event belongs to.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'post_id'     => array( 'description' => __( 'Associated post ID, 0 when not post-related.', 'mj-wsal-bridge' ), 'type' => 'integer', 'readonly' => true ),
					'post_type'   => array( 'description' => __( 'Associated post type.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'post_status' => array( 'description' => __( 'Associated post status.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'meta'        => array( 'description' => __( 'Event metadata, pivoted from name/value pairs into an object.', 'mj-wsal-bridge' ), 'type' => 'object', 'readonly' => true ),
				),
			);
		}

		/**
		 * @return array
		 */
		public static function get_event_type_schema() {
			return array(
				'$schema'    => 'http://json-schema.org/draft-04/schema#',
				'title'      => 'mj_wsal_event_type',
				'type'       => 'object',
				'properties' => array(
					'alert_id'    => array( 'description' => __( 'WP Activity Log event type ID.', 'mj-wsal-bridge' ), 'type' => 'integer', 'readonly' => true ),
					'label'       => array( 'description' => __( 'Short human-readable name.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'message'     => array( 'description' => __( 'Message template for the event.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'severity'    => array( 'description' => __( 'Declared severity level.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'category'    => array( 'description' => __( 'Top-level grouping.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'subcategory' => array( 'description' => __( 'Secondary grouping.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'object'      => array( 'description' => __( 'Subject this event type concerns.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
					'event_type'  => array( 'description' => __( 'Action this event type represents.', 'mj-wsal-bridge' ), 'type' => 'string', 'readonly' => true ),
				),
			);
		}
	}

	MJ_WSAL_Bridge::init();
}
