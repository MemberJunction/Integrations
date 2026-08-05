/**
 * Google Analytics 4 connector, over the Data API v1beta.
 *
 * This class is ORCHESTRATION ONLY. The report catalog, the config parse, the service-account parse,
 * the window arithmetic and cursor codec, and the row projection all live in pure modules beside it
 * with their own tests. What is left here is the part that needs an engine, a clock and a network.
 *
 * ── WHAT MAKES GA4 UNLIKE THE OTHER CONNECTORS ───────────────────────────────────────────────────
 *
 * There is nothing to list. Every other connector in this repo reads an API that has records —
 * `/projects`, `/users`, a CSV of organizations — and the connector's job is to walk them. GA4 has
 * no records. It has a query engine, and a "report" is whatever you ask it for: a set of dimensions,
 * a set of metrics, and a date range, aggregated on demand. So the objects here are *defined
 * reports*, declared in the catalog, and the identity of a row is the dimension tuple that produced
 * it. That has three consequences that shape everything below.
 *
 * 1. **`date` must be a dimension, on every object.** A report aggregated over a range is one answer
 *    whose shape changes whenever the range moves; there is no stable row to upsert. Adding `date`
 *    turns it into one row per day, which is the only form with an identity that survives across
 *    runs.
 *
 * 2. **A day is not final when it ends.** GA4 keeps reprocessing recent events for up to 48 hours,
 *    and user-scoped metrics keep moving for longer. A watermark that advanced strictly forward
 *    would land every day exactly once, at its least accurate, and never revisit it — so the window
 *    opens `lookbackDays` behind the watermark and re-reads the tail. The engine's content-hash
 *    prefetch makes that nearly free: days that did not move cost a read and no write.
 *
 * 3. **The grain is chosen, not given.** Which is why there are three objects rather than one with a
 *    rollup — see the long note in `GA4Objects.ts`. Short version: GA4's user metrics are
 *    cardinalities, cardinalities are not additive, and a rollup that is right for the counts and
 *    quietly wrong for the users is worse than no rollup.
 *
 * ── THE ENGINE CONSTRAINT THIS ANSWERS TO ────────────────────────────────────────────────────────
 *
 * `FetchChangesMs` is 30s, read from a module constant with no per-connector override, and a timeout
 * is classified retryable while the timeout wrapper is a non-cancelling `Promise.race` — so an
 * overrun is not a clean retry, it is the same work running three times concurrently. Every call
 * here therefore issues exactly ONE `runReport` and returns, rather than looping until the batch is
 * full. One request per call is also the honest shape: GA4 pages by offset, and the engine's re-call
 * loop is a perfectly good pump.
 */
import { RegisterClass } from '@memberjunction/global';
import { Metadata, type IMetadataProvider, type UserInfo } from '@memberjunction/core';
import type { MJCompanyIntegrationEntity, MJCredentialEntity } from '@memberjunction/core-entities';
import {
    BaseIntegrationConnector,
    type ConnectionTestResult,
    type ExternalFieldSchema,
    type ExternalObjectSchema,
    type ExternalRecord,
    type FetchBatchResult,
    type FetchContext,
    type FetchWarning,
    type IntegrationObjectInfo,
} from '@memberjunction/integration-engine';

import { parseGA4Config, GA4_MAX_LIMIT, type GA4Config } from './GA4Config.js';
import {
    GA4_OBJECTS,
    catalogObject,
    toIntegrationObjectInfo,
    type CatalogField,
    type CatalogObject,
} from './GA4Objects.js';
import { parseServiceAccount, type GA4ServiceAccount } from './GA4ServiceAccount.js';
import {
    DefaultGA4ReportPort,
    isPermissionError,
    isQuotaError,
    type GA4ReportPort,
    type GA4RunReportRequest,
    type GA4RunReportResponse,
} from './GA4Report.js';
import { projectRow } from './GA4Rows.js';
import {
    formatCursor,
    initialWindow,
    nextWindow,
    parseCursor,
    toISODate,
    type GA4Cursor,
} from './GA4Window.js';

@RegisterClass(BaseIntegrationConnector, 'GA4Connector')
@RegisterClass(BaseIntegrationConnector, '@memberjunction/connector-ga4')
export class GA4Connector extends BaseIntegrationConnector {
    public override get IntegrationName(): string {
        return 'Google Analytics 4';
    }

    /** The watermark is a date that only ever advances toward today. */
    public override get MonotonicWatermark(): boolean {
        return true;
    }

    /**
     * GA4 orders a report by its own default and offers no stable seek key. Position is carried by
     * the cursor's offset against a pinned date range instead — which is exact for the duration of a
     * run, where a sort key would only be approximate.
     */
    public override StableOrderingKey(_objectName: string): string | null {
        return null;
    }

    /** Overridable so tests drive the clock and the API without a credential or a network. */
    protected Now(): Date {
        return new Date();
    }

    protected async Report(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<GA4ReportPort> {
        const account = await this.LoadServiceAccount(companyIntegration, contextUser);
        return new DefaultGA4ReportPort(account.client_email, account.private_key);
    }

    // ── Discovery ─────────────────────────────────────────────────────────────
    // Answered from the declared catalog rather than from seeded metadata, so the connector is usable
    // BEFORE its metadata has been pushed — which is the state it is in at first setup.

    public override GetIntegrationObjects(): IntegrationObjectInfo[] {
        return GA4_OBJECTS.map(toIntegrationObjectInfo);
    }

    public override async DiscoverObjects(
        _companyIntegration: MJCompanyIntegrationEntity,
        _contextUser: UserInfo
    ): Promise<ExternalObjectSchema[]> {
        return GA4_OBJECTS.map((o) => ({
            Name: o.Name,
            Label: o.DisplayName,
            Description: o.Description,
            SupportsIncrementalSync: o.SupportsIncrementalSync,
            SupportsWrite: false,
        }));
    }

    /**
     * MaxLength/Precision/Scale/IsPrimaryKey are set explicitly, and that is load-bearing. The engine
     * has two bridges from a declared catalog into field schemas and they are not equivalent — one
     * carries these attributes, the other drops them. A `--base` connector that leaves them to be
     * inferred gets unbounded columns and hash-based identity instead of key-based.
     */
    public override async DiscoverFields(
        _companyIntegration: MJCompanyIntegrationEntity,
        objectName: string,
        _contextUser: UserInfo
    ): Promise<ExternalFieldSchema[]> {
        return catalogObject(objectName).Fields.map(
            (f: CatalogField): ExternalFieldSchema => ({
                Name: f.Name,
                Label: f.DisplayName,
                Description: f.Description,
                DataType: f.Type,
                IsRequired: f.IsRequired,
                AllowsNull: f.AllowsNull,
                IsPrimaryKey: f.IsPrimaryKey,
                IsUniqueKey: f.IsUniqueKey,
                IsReadOnly: true,
                MaxLength: f.Length ?? null,
                Precision: f.Precision ?? null,
                Scale: f.Scale ?? null,
            })
        );
    }

    // ── Connection ────────────────────────────────────────────────────────────

    /**
     * The smallest report that proves the whole chain: one metric, one dimension, one row, today.
     *
     * It has to be a real report rather than a metadata call, because the ways GA4 setup fails are
     * only distinguishable when you actually query DATA. The credential can be valid, the Data API
     * can be enabled, and the service account can still be unable to read this property — that last
     * step happens in the Analytics UI, not in Cloud Console, and it is the one people miss. So a
     * permission failure is reported as its own case with the fix in the message, rather than as
     * whatever Google's error string happened to say.
     *
     * On success it reports the property's reporting time zone, because every `date` this connector
     * lands is a day in that zone rather than in UTC, and that is not otherwise discoverable from
     * the synced table.
     */
    public override async TestConnection(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo
    ): Promise<ConnectionTestResult> {
        let config: GA4Config;
        try {
            config = parseGA4Config(companyIntegration.Configuration);
        } catch (e) {
            return { Success: false, Message: (e as Error).message };
        }

        let account: GA4ServiceAccount;
        try {
            account = await this.LoadServiceAccount(companyIntegration, contextUser);
        } catch (e) {
            return { Success: false, Message: (e as Error).message };
        }

        const today = toISODate(this.Now());
        try {
            const port = await this.Report(companyIntegration, contextUser);
            const response = await port.RunReport({
                property: `properties/${config.propertyId}`,
                dateRanges: [{ startDate: today, endDate: today }],
                dimensions: [{ name: 'date' }],
                metrics: [{ name: 'sessions' }],
                limit: 1,
                offset: 0,
                returnPropertyQuota: true,
            });
            const zone = response.metadata?.timeZone ?? 'unknown';
            return {
                Success: true,
                Message:
                    `Read property ${config.propertyId} as ${account.client_email}. ` +
                    `Reporting time zone: ${zone} — every synced 'date' is a day in that zone, not UTC.`,
                ServerVersion: 'v1beta',
            };
        } catch (e) {
            if (isPermissionError(e)) {
                return {
                    Success: false,
                    Message:
                        `The service account ${account.client_email} authenticated, but is not permitted to read GA4 property ${config.propertyId}. ` +
                        'A Cloud IAM role is not sufficient: add that email as a property user in Google Analytics → Admin → Property Access Management with at least Viewer. ' +
                        'Also confirm the Google Analytics Data API is enabled on the service account\'s project.',
                };
            }
            if (isQuotaError(e)) {
                return {
                    Success: false,
                    Message: `GA4 quota is exhausted for property ${config.propertyId}; the credential itself looks fine. Analytics token buckets refill hourly and daily — retry later. (${(e as Error).message})`,
                };
            }
            return {
                Success: false,
                Message: `GA4 runReport failed for property ${config.propertyId}: ${(e as Error).message}`,
            };
        }
    }

    // ── Fetch ─────────────────────────────────────────────────────────────────

    /**
     * One `runReport` per call — see the 30s note in the class docs.
     *
     * The call resolves its position from the cursor, or opens the run's first window from the
     * watermark. It returns `HasMore: true` with a fresh cursor for as long as there is either more
     * of this window to page or another window to open, and only on the very last page of the very
     * last window does it emit `NewWatermarkValue`.
     *
     * The watermark is the run's PINNED `today`, not the newest date actually seen in the data. Those
     * differ whenever a property has no traffic on its most recent days, and using the data's own
     * maximum would leave the watermark stuck behind a quiet weekend, re-reading the same empty range
     * on every run until traffic resumed.
     */
    public override async FetchChanges(ctx: FetchContext): Promise<FetchBatchResult> {
        const obj = catalogObject(ctx.ObjectName);
        const config = parseGA4Config(ctx.CompanyIntegration.Configuration);
        const port = await this.Report(ctx.CompanyIntegration, ctx.ContextUser);

        const cursor = this.ResolveCursor(ctx, config);
        const limit = Math.max(1, Math.min(ctx.BatchSize, GA4_MAX_LIMIT));

        const request: GA4RunReportRequest = {
            property: `properties/${config.propertyId}`,
            dateRanges: [{ startDate: cursor.From, endDate: cursor.To }],
            dimensions: obj.Dimensions.map((name) => ({ name })),
            metrics: obj.Metrics.map((name) => ({ name })),
            limit,
            offset: cursor.Offset,
            returnPropertyQuota: true,
        };

        let response: GA4RunReportResponse;
        try {
            response = await port.RunReport(request);
        } catch (e) {
            // Rethrown with the window attached. A bare Google error names neither the property nor
            // the date range, and "which request failed" is the first thing anyone needs.
            throw new Error(
                `GA4 runReport failed for ${ctx.ObjectName} on property ${config.propertyId} over ${cursor.From}..${cursor.To} (offset ${cursor.Offset}): ${(e as Error).message}`
            );
        }

        const { records, warnings } = this.ProjectRows(obj, response, config, cursor);

        // GA4 reports the full match count on every page, so exhaustion of a window is knowable
        // without probing for an empty page. Falling back to the consumed count when `rowCount` is
        // absent makes a short page mean "done" rather than looping forever on a missing field, and
        // the `rowsReturned > 0` guard makes an empty page terminal under any response shape.
        const rowsReturned = response.rows?.length ?? 0;
        const consumed = cursor.Offset + rowsReturned;
        const total = typeof response.rowCount === 'number' ? response.rowCount : consumed;

        const next: GA4Cursor | null =
            consumed < total && rowsReturned > 0
                ? { ...cursor, Offset: consumed }
                : this.AdvanceWindow(cursor, config);

        return {
            Records: records,
            HasMore: next !== null,
            NextCursor: next ? formatCursor(next) : undefined,
            // Only when the whole run is done. Advancing mid-run would let a crash mark days ingested
            // that were never read, and the lookback window is not wide enough to recover an
            // arbitrary gap.
            NewWatermarkValue: next === null ? cursor.Today : undefined,
            Warnings: warnings.length > 0 ? warnings : undefined,
        };
    }

    /** Resume where the run left off, or open the run's first window from the watermark. */
    private ResolveCursor(ctx: FetchContext, config: GA4Config): GA4Cursor {
        const existing = parseCursor(ctx.CurrentCursor);
        if (existing) return existing;

        const today = toISODate(this.Now());
        const window = initialWindow(config, ctx.WatermarkValue, today);
        return { Today: today, From: window.From, To: window.To, Offset: 0 };
    }

    /** Move to the next date window, or null when the run has reached its pinned `today`. */
    private AdvanceWindow(cursor: GA4Cursor, config: GA4Config): GA4Cursor | null {
        const window = nextWindow(cursor, config, cursor.Today);
        return window ? { Today: cursor.Today, From: window.From, To: window.To, Offset: 0 } : null;
    }

    /**
     * Project the response, collecting the conditions worth warning about.
     *
     * These are all things GA4 reports about the DATA rather than about the request, so none of them
     * fails a run — but each one means the landed numbers do not say what they appear to say, and
     * that must not be invisible.
     */
    private ProjectRows(
        obj: CatalogObject,
        response: GA4RunReportResponse,
        config: GA4Config,
        cursor: GA4Cursor
    ): { records: ExternalRecord[]; warnings: FetchWarning[] } {
        const records: ExternalRecord[] = [];
        const warnings: FetchWarning[] = [];
        let unkeyable = 0;
        let otherRows = 0;

        for (const row of response.rows ?? []) {
            const projected = projectRow(obj, row, config.propertyId);
            if (projected === null) {
                unkeyable++;
                continue;
            }
            if (projected.IsOtherRow) otherRows++;
            records.push(projected.Record);
        }

        if (unkeyable > 0) {
            warnings.push({
                Code: 'UNKEYABLE_ROW',
                Message: `${unkeyable} row(s) skipped: GA4 returned a value for the 'date' dimension that is not a date, so the row has no stable identity.`,
                Data: { count: unkeyable, window: `${cursor.From}..${cursor.To}` },
            });
        }

        if (response.metadata?.dataLossFromOtherRow || otherRows > 0) {
            // The rows are still emitted — they are real traffic, and dropping them would silently
            // shrink every total computed from this table. The warning is what stops '(other)' from
            // being read as a campaign name.
            warnings.push({
                Code: 'CARDINALITY_LIMIT',
                Message:
                    `GA4 hit a cardinality limit for ${obj.Name} over ${cursor.From}..${cursor.To} and collapsed some rows into an '(other)' aggregate. ` +
                    'Totals stay complete but the detail behind those rows is gone. Lower Configuration.maxWindowDays so each request covers a narrower range.',
                Data: { object: obj.Name, otherRows, window: `${cursor.From}..${cursor.To}` },
            });
        }

        if (response.metadata?.subjectToThresholding) {
            warnings.push({
                Code: 'DATA_THRESHOLDED',
                Message:
                    `GA4 withheld rows for ${obj.Name} over ${cursor.From}..${cursor.To} because the underlying audience was too small to report without identifying individuals. ` +
                    'Thresholding applies when Google signals are enabled; the landed rows undercount by an amount GA4 does not disclose.',
                Data: { object: obj.Name, window: `${cursor.From}..${cursor.To}` },
            });
        }

        const remainingHourly = response.propertyQuota?.tokensPerHour?.remaining;
        if (typeof remainingHourly === 'number' && remainingHourly <= 0) {
            warnings.push({
                Code: 'QUOTA_EXHAUSTED',
                Message: `GA4 analytics tokens for this hour are exhausted on property ${config.propertyId}. Later requests in this run will fail until the bucket refills.`,
                Data: { propertyId: config.propertyId },
            });
        }

        return { records, warnings };
    }

    // ── Credentials ───────────────────────────────────────────────────────────

    /**
     * The service-account key comes from `MJ: Credentials` and nowhere else.
     *
     * Not from `CompanyIntegration.Configuration`, which carries the non-secret half, and not from a
     * process env var — the legacy provider accepted a `GA4_SA_JSON` fallback, which made the
     * effective credential depend on the host's environment rather than on the record, so two
     * companies on one MJAPI could silently read the same property. And explicitly not from
     * `CompanyIntegration.APIKey`: that column is not decrypt-on-read, so an mj-sync-encrypted value
     * comes back as the literal `$ENC$…` string and would be handed to Google verbatim.
     */
    protected async LoadServiceAccount(
        companyIntegration: MJCompanyIntegrationEntity,
        contextUser: UserInfo,
        provider?: IMetadataProvider
    ): Promise<GA4ServiceAccount> {
        const credentialID = companyIntegration.CredentialID;
        if (!credentialID) {
            throw new Error(
                'GA4: CompanyIntegration.CredentialID is not set. Create an MJ: Credentials record of type "Google Service Account" holding the downloaded key JSON and link it — the key is never read from Configuration.'
            );
        }

        const md = provider ?? new Metadata();
        const credential = await md.GetEntityObject<MJCredentialEntity>('MJ: Credentials', contextUser);
        const loaded = await credential.Load(credentialID);
        if (!loaded) {
            throw new Error(
                `GA4: credential ${credentialID} could not be loaded. It may have been deleted, or this user may not have access to it.`
            );
        }
        return parseServiceAccount(credential.Values);
    }
}

/** Tree-shaking prevention function — import and call from the module entry point. */
export function LoadGA4Connector(): void { /* no-op */ }
