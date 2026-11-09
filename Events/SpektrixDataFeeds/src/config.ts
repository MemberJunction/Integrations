import { z } from 'zod';
import { PII_MODES } from './pii/policy.js';

/**
 * Connection-level settings, read from `CompanyIntegration.Configuration` (JSON). Everything has a
 * safe default; `piiMode` defaults to the protective setting so a connection only ever lands raw
 * personal data when someone wrote `"piiMode": "raw"` on purpose.
 */
export const ZConnectionSettings = z
    .object({
        piiMode: z.enum(PII_MODES).default('pseudonymize'),
        /** Attribute names whose values survive pseudonymize/suppress. */
        piiAttributeAllowlist: z.array(z.string()).default([]),
        /** A watermark written under one mode refuses to continue under another unless this is set. */
        allowPiiModeChange: z.boolean().default(false),
        /** First `From` when no watermark exists yet (ISO date or date-time). */
        fetchWindowStart: z.string().default('2000-01-01T00:00:00Z'),
        /** Width of each `GetCustomerData` window in days. The service prepares a whole window before sending a byte. */
        windowDays: z.number().int().min(1).max(3660).default(30),
        /** Passed to the client: destroy the connection after this long with no bytes. */
        idleTimeoutMs: z.number().int().min(1000).default(60 * 60 * 1000),
        /** Overall ceiling for one window request. */
        requestTimeoutMs: z.number().int().min(1000).default(2 * 60 * 60 * 1000),
        /** How long the header lists (tags, merges, …) from the last call are reused for the lookup objects. */
        lookupCacheMs: z.number().int().min(0).default(10 * 60 * 1000),
        /** Non-secret connection facts may also live here when the credential record omits them. */
        ClientName: z.string().optional(),
        Endpoint: z.string().optional(),
    })
    .passthrough();

export type ConnectionSettings = z.infer<typeof ZConnectionSettings>;

/** Values on the connection's `MJ: Credentials` record (credential type "Spektrix Data Feeds Certificate"). */
export interface CredentialValues {
    ClientName?: string;
    CertificatePfxBase64?: string;
    CertificatePassphrase?: string;
    PseudonymKey?: string;
    Endpoint?: string;
}

export function ParseJsonObject(text: string | null | undefined): Record<string, unknown> | null {
    if (!text || text.trim() === '') return null;
    try {
        const parsed: unknown = JSON.parse(text);
        return parsed !== null && typeof parsed === 'object' && !Array.isArray(parsed) ? (parsed as Record<string, unknown>) : null;
    } catch {
        return null;
    }
}

export function ParseConnectionSettings(configurationJson: string | null | undefined): ConnectionSettings {
    const parsed = ZConnectionSettings.safeParse(ParseJsonObject(configurationJson) ?? {});
    if (!parsed.success) {
        // Name the offending keys only — never echo a value from the configuration.
        const keys = [...new Set(parsed.error.issues.map((i) => i.path.join('.')))].join(', ');
        throw new Error(`Invalid Spektrix Data Feeds connection configuration (${keys}).`);
    }
    return parsed.data;
}

export function ReadNonEmptyString(source: Record<string, unknown> | null, key: string): string | undefined {
    const v = source?.[key];
    return typeof v === 'string' && v.trim() !== '' ? v.trim() : undefined;
}
