// Vendored into this Open App from the MemberJunction monorepo (@memberjunction/integration-engine 6.x),
// because the published 5.x line this package compiles against does not export it yet.
/**
 * HmacRequestSigner — shared HMAC request-signing primitives for REST integration connectors.
 *
 * A family of vendor auth schemes signs every request with a keyed hash over a CANONICAL STRING
 * the connector assembles from the request (method, full URL, date header, a content digest of
 * the body, …) and sends the result in a custom `Authorization` header. The vendor-specific part is
 * only the canonical string and the header format; the cryptographic part is always the same three
 * primitives:
 *
 *   1. decode a base-64 shared secret into the raw HMAC key bytes,
 *   2. HMAC the canonical string (UTF-8) with that key and base-64 the raw digest,
 *   3. base-64 the raw MD5 digest of the request body (the classic Content-MD5 shape).
 *
 * They live here, behind one tested helper, so concrete connectors never inline crypto (the
 * connector-code-conventions "no inline crypto" rule) and so a malformed secret produces one clear,
 * secret-free error everywhere instead of a silently-wrong key (Node's base-64 decoder is lenient:
 * it skips characters it does not understand rather than failing).
 *
 * Nothing here logs, caches, or echoes key material.
 */
import { createHash, createHmac } from 'node:crypto';

/** HMAC digest algorithms supported by {@link ComputeHmacBase64}. */
export type HmacDigestAlgorithm = 'sha1' | 'sha256' | 'sha512';

/**
 * Raised when a shared secret that must be base-64 is not. The message names the credential by its
 * LABEL only — the secret value itself is never included, so the error is safe to log and surface.
 */
export class HmacKeyFormatError extends Error {
    /** The credential label the caller supplied (e.g. "ApiSecretKey"). */
    public readonly KeyLabel: string;

    constructor(keyLabel: string, reason: string) {
        super(`${keyLabel} is not a valid base-64 signing key (${reason}). Re-enter the secret exactly as issued by the vendor.`);
        this.name = 'HmacKeyFormatError';
        this.KeyLabel = keyLabel;
    }
}

/** Standard (RFC 4648 §4) base-64 alphabet with correct padding; whitespace is stripped first. */
const STRICT_BASE64 = /^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/;

/**
 * Decodes a base-64 shared secret into raw key bytes, STRICTLY.
 *
 * Interior whitespace / line breaks (common when a secret is pasted from an email or a wrapped
 * console) are removed before validation. Anything else outside the standard alphabet, bad padding,
 * or an empty result raises {@link HmacKeyFormatError} — never a crash and never a silently
 * truncated key that would produce signatures the vendor rejects with a confusing 401.
 *
 * @param encoded  The base-64 secret as stored on the credential.
 * @param keyLabel Human-facing name of the credential field, used in the error message only.
 */
export function DecodeBase64SigningKey(encoded: string, keyLabel: string = 'signing key'): Buffer {
    if (typeof encoded !== 'string') {
        throw new HmacKeyFormatError(keyLabel, 'value is not a string');
    }
    const compact = encoded.replace(/\s+/g, '');
    if (compact.length === 0) {
        throw new HmacKeyFormatError(keyLabel, 'value is empty');
    }
    if (!STRICT_BASE64.test(compact)) {
        throw new HmacKeyFormatError(keyLabel, 'contains characters outside the base-64 alphabet or has invalid padding');
    }
    const key = Buffer.from(compact, 'base64');
    if (key.length === 0) {
        throw new HmacKeyFormatError(keyLabel, 'decodes to zero bytes');
    }
    return key;
}

/**
 * HMACs `message` (encoded as UTF-8) with `key` and returns the RAW digest, base-64 encoded.
 *
 * @param algorithm The digest algorithm (e.g. `'sha1'` for HMAC-SHA1).
 * @param key       The raw key bytes — typically the output of {@link DecodeBase64SigningKey}.
 * @param message   The canonical string-to-sign.
 */
export function ComputeHmacBase64(algorithm: HmacDigestAlgorithm, key: Buffer, message: string): string {
    return createHmac(algorithm, key).update(message, 'utf8').digest('base64');
}

/**
 * Base-64 of the raw 16-byte MD5 digest of `body` encoded as UTF-8 (the Content-MD5 shape many
 * HMAC schemes fold into their canonical string). An empty string is a valid body and hashes to
 * `1B2M2Y8AsgTpgAmY7PhCfg==`.
 */
export function ComputeBodyMd5Base64(body: string): string {
    return createHash('md5').update(body, 'utf8').digest('base64');
}
