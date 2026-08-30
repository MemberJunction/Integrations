<?php
/**
 * Plugin Name: MJ WP Activity Log Bridge
 * Description: Exposes WP Activity Log (WSAL) events over the WordPress REST API, read-only, so the MemberJunction WordPress connector can discover and sync them like any other collection. Registers no writes and stores no data of its own.
 * Version:     1.0.0
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
