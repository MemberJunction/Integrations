/**
 * Parsing and validation of the Google service-account key.
 *
 * Pure and dependency-free, because every interesting failure here happens at setup time on someone
 * else's machine and the only way to make those failures cheap is to name them precisely. A service
 * account that authenticates but cannot read the property, or a key whose newlines were eaten in
 * transit, both surface as an opaque Google error several layers down; caught here they are one
 * sentence each.
 */

/** The fields of a Google service-account JSON this connector actually uses. */
export interface GA4ServiceAccount {
    client_email: string;
    private_key: string;
    project_id?: string;
    private_key_id?: string;
}

/**
 * The shapes a credential can legitimately arrive in.
 *
 * `MJ: Credentials.Values` is a JSON document, and how an operator puts a service-account key into
 * it varies: pasted as a nested object, pasted as an escaped string, or — because the downloaded
 * file IS the whole credential — pasted as the service-account JSON itself with no wrapper. All
 * three are accepted. Rejecting two of them would be pure ceremony: they are unambiguous, and the
 * alternative is a support conversation about JSON nesting.
 */
export function parseServiceAccount(values: string | null | undefined): GA4ServiceAccount {
    if (!values || !values.trim()) {
        throw new Error(
            'GA4: no credential is linked. Set CompanyIntegration.CredentialID to an MJ: Credentials record whose Values hold the Google service-account JSON, e.g. {"serviceAccountJSON": { ... }}.'
        );
    }

    const root = parseJSON(values, 'the credential Values');
    // Wrapped under a key, or the service-account JSON at the top level.
    const candidate =
        pickObject(root, 'serviceAccountJSON') ??
        pickObject(root, 'ServiceAccountJSON') ??
        pickObject(root, 'serviceAccountKey') ??
        root;

    const clientEmail = typeof candidate.client_email === 'string' ? candidate.client_email.trim() : '';
    const privateKeyRaw = typeof candidate.private_key === 'string' ? candidate.private_key : '';

    if (!clientEmail || !privateKeyRaw) {
        throw new Error(
            'GA4: the linked credential does not contain a Google service-account key. Expected client_email and private_key — either at the top level of Values, or under a "serviceAccountJSON" key. ' +
                'Use the JSON file downloaded from Google Cloud Console → IAM & Admin → Service Accounts → Keys, verbatim.'
        );
    }

    const privateKey = normalizePrivateKey(privateKeyRaw);
    if (!privateKey.includes('BEGIN PRIVATE KEY')) {
        throw new Error(
            'GA4: the credential\'s private_key does not look like a PEM key (no "BEGIN PRIVATE KEY" header). It is likely truncated, or the private_key_id was pasted in its place.'
        );
    }

    return {
        client_email: clientEmail,
        private_key: privateKey,
        project_id: typeof candidate.project_id === 'string' ? candidate.project_id : undefined,
        private_key_id: typeof candidate.private_key_id === 'string' ? candidate.private_key_id : undefined,
    };
}

/**
 * Restore real newlines in a PEM key.
 *
 * A service-account key is a multi-line PEM stored inside a JSON string, so it legitimately contains
 * `\n` escapes. Whether those survive as escapes or arrive already-unescaped depends on how many
 * times the value has been through a JSON round-trip on its way here — via an env var, a shell
 * variable, a form field, a copy-paste. Both forms are common and only one of them is a valid key,
 * so the escaped form is converted rather than rejected. This is the single most common GA4
 * credential failure and it otherwise surfaces as "error:1E08010C:DECODER routines::unsupported".
 *
 * The order matters: `\\n` (an escaped backslash followed by n, i.e. a literal backslash in the key)
 * is left alone, and only a lone `\n` escape becomes a newline.
 */
export function normalizePrivateKey(key: string): string {
    const unescaped = key.includes('\n') ? key : key.replace(/\\n/g, '\n');
    // Windows line endings inside a PEM are tolerated by OpenSSL but not by every parser in the
    // chain; normalizing costs nothing and removes a whole class of "works on my machine".
    return unescaped.replace(/\r\n/g, '\n').trim();
}

function parseJSON(text: string, what: string): Record<string, unknown> {
    let parsed: unknown;
    try {
        parsed = JSON.parse(text);
    } catch (e) {
        throw new Error(`GA4: could not parse ${what} as JSON: ${(e as Error).message}`);
    }
    if (parsed === null || typeof parsed !== 'object' || Array.isArray(parsed)) {
        throw new Error(`GA4: ${what} must be a JSON object.`);
    }
    return parsed as Record<string, unknown>;
}

function pickObject(root: Record<string, unknown>, key: string): Record<string, unknown> | null {
    const v = root[key];
    if (v !== null && typeof v === 'object' && !Array.isArray(v)) return v as Record<string, unknown>;
    // Also accept the nested key stored as an escaped JSON string.
    if (typeof v === 'string' && v.trim().startsWith('{')) {
        try {
            const inner: unknown = JSON.parse(v);
            if (inner !== null && typeof inner === 'object' && !Array.isArray(inner)) {
                return inner as Record<string, unknown>;
            }
        } catch {
            return null;
        }
    }
    return null;
}
