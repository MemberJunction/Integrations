import { describe, it, expect } from 'vitest';
import { createHash, createHmac } from 'node:crypto';
import {
    DecodeBase64SigningKey,
    ComputeHmacBase64,
    ComputeBodyMd5Base64,
    HmacKeyFormatError,
} from '../HmacRequestSigner.js';

describe('HmacRequestSigner', () => {
    describe('DecodeBase64SigningKey', () => {
        it('decodes a standard base-64 secret to its raw bytes', () => {
            const raw = Buffer.from('not-a-real-secret-only-a-test-vector', 'utf8');
            const decoded = DecodeBase64SigningKey(raw.toString('base64'), 'ApiSecretKey');
            expect(decoded.equals(raw)).toBe(true);
        });

        it('tolerates whitespace / line wrapping inside the pasted secret', () => {
            const raw = Buffer.from('wrapped-secret-value-for-testing', 'utf8');
            const b64 = raw.toString('base64');
            const wrapped = `  ${b64.slice(0, 10)}\n${b64.slice(10)}  `;
            expect(DecodeBase64SigningKey(wrapped).equals(raw)).toBe(true);
        });

        it.each([
            ['empty', ''],
            ['whitespace only', '   '],
            ['outside the alphabet', 'abc$def!'],
            ['bad padding', 'abc=='],
            ['url-safe alphabet', 'ab-_cd=='],
        ])('rejects a %s secret with HmacKeyFormatError naming only the label', (_label, value) => {
            let caught: unknown;
            try {
                DecodeBase64SigningKey(value, 'ApiSecretKey');
            } catch (err) {
                caught = err;
            }
            expect(caught).toBeInstanceOf(HmacKeyFormatError);
            const error = caught as HmacKeyFormatError;
            expect(error.KeyLabel).toBe('ApiSecretKey');
            expect(error.message).toContain('ApiSecretKey');
            if (value.trim().length > 0) expect(error.message).not.toContain(value);
        });
    });

    describe('ComputeHmacBase64', () => {
        it('matches node:crypto HMAC-SHA1 over the UTF-8 message', () => {
            const key = Buffer.from('k3y-bytes', 'utf8');
            const message = 'GET\nhttps://example.invalid/api/v3/events?x=1\nMon, 21 Oct 2020 07:28:00 GMT';
            const expected = createHmac('sha1', key).update(message, 'utf8').digest('base64');
            expect(ComputeHmacBase64('sha1', key, message)).toBe(expected);
        });

        it('encodes non-ASCII message text as UTF-8', () => {
            const key = Buffer.from('k', 'utf8');
            const message = 'POST\nhttps://example.invalid/é\nDate';
            const expected = createHmac('sha256', key).update(Buffer.from(message, 'utf8')).digest('base64');
            expect(ComputeHmacBase64('sha256', key, message)).toBe(expected);
        });
    });

    describe('ComputeBodyMd5Base64', () => {
        it('is the base-64 of the raw 16-byte MD5 digest', () => {
            const body = '{"firstName":"Test"}';
            const expected = createHash('md5').update(body, 'utf8').digest('base64');
            expect(ComputeBodyMd5Base64(body)).toBe(expected);
            expect(Buffer.from(ComputeBodyMd5Base64(body), 'base64').length).toBe(16);
        });

        it('hashes the empty body to the well-known MD5 of ""', () => {
            expect(ComputeBodyMd5Base64('')).toBe('1B2M2Y8AsgTpgAmY7PhCfg==');
        });
    });
});
