import * as http from 'node:http';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { afterEach, describe, expect, it } from 'vitest';
import { ClearSpektrixDataFeedClientFactory } from '../datafeeds/clientRegistry.js';
import { EncodeNrbfCustomerForTest } from '../datafeeds/nrbf.js';
import type { DataFeedCustomer, DataFeedLookups } from '../datafeeds/types.js';
import { SpektrixWcfDataFeedClient } from '../datafeeds/wcfClient.js';
import { DescribeError, SpektrixDataFeedsConnector } from '../SpektrixDataFeedsConnector.js';
import { registerConnector } from '../index.js';
import type { UserInfo } from '@memberjunction/core';
import type { MJCompanyIntegrationEntity } from '@memberjunction/core-entities';

const here = dirname(fileURLToPath(import.meta.url));
const FIXTURE = JSON.parse(readFileSync(join(here, 'fixtures', 'customers.synthetic.json'), 'utf8')) as {
    lookups: DataFeedLookups;
    customers: DataFeedCustomer[];
};

const servers: http.Server[] = [];

afterEach(async () => {
    ClearSpektrixDataFeedClientFactory();
    while (servers.length > 0) {
        const s = servers.pop()!;
        await new Promise<void>((resolve) => s.close(() => resolve()));
    }
});

function listenServer(handler: http.RequestListener): Promise<string> {
    return new Promise((resolve) => {
        const server = http.createServer(handler);
        servers.push(server);
        server.listen(0, '127.0.0.1', () => {
            const addr = server.address() as { port: number };
            resolve(`http://127.0.0.1:${addr.port}/datafeeds.svc`);
        });
    });
}

function buildMtomBody(boundary: string, nrbfBytes: Buffer): Buffer {
    const xml =
        '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">' +
        '<s:Header>' +
        '<h:DataProtectionStatements xmlns:h="http://system.spektrix.com/api/datafeeds/" xmlns:d="http://schemas.datacontract.org/2004/07/Spektrix.DataFeeds.Data">' +
        '<d:DataProtectionStatement><d:Id>1</d:Id><d:Name>Email marketing</d:Name></d:DataProtectionStatement>' +
        '</h:DataProtectionStatements>' +
        '<h:Merges xmlns:h="http://system.spektrix.com/api/datafeeds/" xmlns:d="http://schemas.datacontract.org/2004/07/Spektrix.DataFeeds.Data">' +
        '<d:CustomerMerge><d:Date>2025-03-04T10:15:00</d:Date><d:From>1002</d:From><d:To>1001</d:To></d:CustomerMerge>' +
        '</h:Merges>' +
        '<h:TagGroups xmlns:h="http://system.spektrix.com/api/datafeeds/" xmlns:d="http://schemas.datacontract.org/2004/07/Spektrix.DataFeeds.Data">' +
        '<d:TagGroup><d:Id>1</d:Id><d:Name>Segments &amp; VIP</d:Name></d:TagGroup>' +
        '</h:TagGroups>' +
        '<h:Tags xmlns:h="http://system.spektrix.com/api/datafeeds/" xmlns:d="http://schemas.datacontract.org/2004/07/Spektrix.DataFeeds.Data">' +
        '<d:Tag><d:Id>10</d:Id><d:Name>Subscriber</d:Name><d:TagGroupId>1</d:TagGroupId></d:Tag>' +
        '</h:Tags>' +
        '</s:Header>' +
        '<s:Body><CustomerDataMessage xmlns="http://system.spektrix.com/api/datafeeds/"><Customers><xop:Include href="cid:customers@spektrix" xmlns:xop="http://www.w3.org/2004/08/xop/include"/></Customers></CustomerDataMessage></s:Body>' +
        '</s:Envelope>';

    const part1 =
        `--${boundary}\r\n` +
        'Content-Type: application/xop+xml;charset=utf-8;type="text/xml"\r\n' +
        'Content-ID: <root@spektrix>\r\n\r\n' +
        xml +
        '\r\n';
    const part2Head =
        `--${boundary}\r\n` +
        'Content-Type: application/octet-stream\r\n' +
        'Content-ID: <customers@spektrix>\r\n\r\n';
    const epilogue = `\r\n--${boundary}--\r\n`;

    return Buffer.concat([
        Buffer.from(part1, 'utf8'),
        Buffer.from(part2Head, 'utf8'),
        nrbfBytes,
        Buffer.from(epilogue, 'utf8'),
    ]);
}

describe('SpektrixWcfDataFeedClient + MS-NRBF streaming decoder', () => {
    it('decodes SOAP MTOM XML headers and length-framed MS-NRBF Person + Organisation graphs end-to-end with SpektrixDataFeedsConnector', async () => {
        const boundary = 'uuid:test-mtom-boundary-1';
        const nrbfPayload = Buffer.concat(FIXTURE.customers.map((c) => EncodeNrbfCustomerForTest(c, true)));
        const mtomBody = buildMtomBody(boundary, nrbfPayload);

        let seenSoapAction = '';
        let seenReqXml = '';
        const endpoint = await listenServer((req, res) => {
            seenSoapAction = String(req.headers['soapaction'] ?? '');
            const chunks: Buffer[] = [];
            req.on('data', (d) => chunks.push(Buffer.from(d)));
            req.on('end', () => {
                seenReqXml = Buffer.concat(chunks).toString('utf8');
                res.writeHead(200, {
                    'Content-Type': `multipart/related; type="application/xop+xml"; boundary="${boundary}"; start="<root@spektrix>"`,
                });
                // Write in intentionally small awkward chunks across binary boundaries
                res.write(mtomBody.subarray(0, 120));
                res.write(mtomBody.subarray(120, 450));
                res.end(mtomBody.subarray(450));
            });
        });

        registerConnector();
        class LocalConnector extends SpektrixDataFeedsConnector {
            protected override async LoadCredentialValues() {
                return {
                    ClientName: 'villagetheatre',
                    CertificatePfxBase64: Buffer.from('test').toString('base64'),
                    PseudonymKey: 'unit-test-key-0123456789abcdef',
                    Endpoint: endpoint,
                };
            }
        }
        const connector = new LocalConnector();
        const ci = {
            ID: 'ci-wcf-1',
            CredentialID: null,
            Configuration: JSON.stringify({
                anonymizePII: true,
                fetchWindowStart: '2026-10-01T00:00:00Z',
                windowDays: 90,
            }),
        } as unknown as MJCompanyIntegrationEntity;

        const batch = await connector.FetchChanges({
            CompanyIntegration: ci,
            ObjectName: 'Customer',
            WatermarkValue: null,
            BatchSize: 100,
            ContextUser: {} as UserInfo,
        });

        expect(seenSoapAction).toContain('IDataFeed/GetCustomerData');
        expect(seenReqXml).toContain('<From>2026-10-01T00:00:00.000Z</From>');
        expect(batch.Records).toHaveLength(3);
        expect(batch.Records.map((r) => r.ExternalID)).toEqual(['1001', '1002', '2001']);
        // Verify raw PII was scrubbed before leaving FetchChanges
        const serialized = JSON.stringify(batch.Records);
        expect(serialized).not.toContain('Zebediah');
        expect(serialized).not.toContain('Fixturesmith');
        expect(serialized).not.toContain('123 Synthetic Street');
        expect(serialized).not.toContain('wheelchair');
        expect(batch.Records[0]!.Fields['email']).toMatch(/@example\.invalid$/);
        expect(batch.Records[0]!.Fields['address_postcode']).toBe('123');
        expect(batch.Records[0]!.Fields['birthDate']).toBe('1980-01-01T00:00:00.0000000');
        expect(batch.Records[2]!.Fields['type']).toBe('Organisation');

        const tagGroups = await connector.FetchChanges({
            CompanyIntegration: ci,
            ObjectName: 'TagGroup',
            WatermarkValue: null,
            BatchSize: 100,
            ContextUser: {} as UserInfo,
        });
        expect(tagGroups.Records[0]!.Fields['name']).toBe('Segments & VIP');
    });

    it('extracts SOAP Fault code without leaking vendor message body', async () => {
        const endpoint = await listenServer((_req, res) => {
            res.writeHead(500, { 'Content-Type': 'text/xml; charset=utf-8' });
            res.end(
                '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body><s:Fault>' +
                    '<faultcode>a:AccessDenied</faultcode><faultstring>secret tenant xyz denied</faultstring>' +
                    '</s:Fault></s:Body></s:Envelope>',
            );
        });

        const client = new SpektrixWcfDataFeedClient({
            clientName: 'villagetheatre',
            pfx: Buffer.from('stub'),
            endpoint,
        });

        let caught: unknown;
        try {
            await client.getCustomerData();
        } catch (err) {
            caught = err;
        }
        expect(DescribeError(caught)).toBe('The Spektrix Data Feeds service returned a SOAP fault (a:AccessDenied).');
        expect(DescribeError(caught)).not.toContain('xyz');
    });

    it('throws ClientCertificateError when https endpoint receives invalid pfx bytes', async () => {
        const client = new SpektrixWcfDataFeedClient({
            clientName: 'villagetheatre',
            pfx: Buffer.from('not-a-valid-pkcs12-bundle'),
            passphrase: 'bad',
            endpoint: 'https://127.0.0.1:65530/datafeeds.svc',
        });

        let caught: unknown;
        try {
            await client.getCustomerData();
        } catch (err) {
            caught = err;
        }
        expect((caught as Error).name).toBe('ClientCertificateError');
        expect(DescribeError(caught)).toContain('AES-256');
    });
});
