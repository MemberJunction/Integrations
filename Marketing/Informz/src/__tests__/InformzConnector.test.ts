import { describe, it, expect } from 'vitest';
import { InformzConnector, InformzRequestError, type InformzAuthContext } from '../InformzConnector.js';

// ─── Fixtures ──────────────────────────────────────────────────────────────
// Every XML shape below descends from the pinned Higher Logic help-centre corpus (212 articles,
// sha256 b6db52dc62c6…), NOT from a live tenant:
//   • the in-body credential block + GridRequest envelope — article 360044600992
//     ("Sample Message (Encryption & Compression)"), the same shape repeated in 37 of 212 articles;
//   • <Record> per returned entity + the 1,000-row cap — article 360033049251 ("Grid Requests Overview").
// Synthetic-but-shaped; credential-free [B] ceiling, so no live endpoint is contacted and no PII appears.

const AUTH: InformzAuthContext = {
    User: 'informz',
    Password: 'sup3rs3cret',
    BrandID: '1234',
    BrandName: 'My Brand',
    Endpoint: 'https://partner.informz.net/aapi/InformzService.svc',
    Namespace: 'http://partner.informz.net/aapi/2009/08/',
    PageSize: 1000,
};

/**
 * A grid response carrying two subscriber Records, in the vendor's documented read shape:
 * `<Record row="n"><Fields><Field element="col">value</Field>…`. The datum is an attribute-named
 * `<Field>`, NOT a child element named after the column — verbatim per article 360033049151
 * ("GridRequests - Subscriber Form Usage"); this same shape appears in 22 of the 212 pinned articles.
 * An empty `<Field/>` is the vendor's NULL.
 */
const SUBSCRIBER_GRID_XML = `<?xml version="1.0" encoding="utf-8"?>
<GridResponse xmlns="http://partner.informz.net/aapi/2009/08/">
  <Grid type="subscriber">
    <Record row="1">
      <Fields>
        <Field element="subscriber_id">1001</Field>
        <Field element="email_address">ada@example.org</Field>
        <Field element="modified_date">2018-03-02T09:41:07.5</Field>
      </Fields>
    </Record>
    <Record row="2">
      <Fields>
        <Field element="subscriber_id">1002</Field>
        <Field element="email_address">grace@example.org</Field>
        <Field element="modified_date" />
      </Fields>
    </Record>
  </Grid>
</GridResponse>`;

const connector = (): InformzConnector => new InformzConnector();

// ─── Identity + capabilities ───────────────────────────────────────────────

describe('InformzConnector identity', () => {
    it('exposes the verbatim MJ: Integrations.Name (three-way identity invariant)', () => {
        expect(connector().IntegrationName).toBe('informz');
    });

    it('declares the write surface the AAPI actually documents', () => {
        const c = connector();
        // ActionRequest documents exist for create/update; the AAPI publishes NO delete action.
        expect(c.SupportsCreate).toBe(true);
        expect(c.SupportsUpdate).toBe(true);
        expect(c.SupportsDelete).toBe(false);
    });

    it('does NOT treat discovery as authoritative', () => {
        // The AAPI has no describe-all endpoint (PROVEN NEGATIVE over the 212-article corpus), so an
        // object absent from a sample must never be deactivated on the strength of that absence.
        expect(connector().DiscoveryIsAuthoritative).toBe(false);
    });
});

// ─── Request construction ──────────────────────────────────────────────────

describe('BuildGridRequestDocument', () => {
    it('places credentials IN THE BODY, with BrandID as the @id attribute and BrandName as the text', () => {
        const xml = connector().BuildGridRequestDocument(AUTH, [
            { GridType: 'subscriber', Conditions: [], ReturnFields: ['subscriber_id'], SortField: null, SortOrder: 'asc', StartRow: null, NumberOfRows: null },
        ]);
        expect(xml).toContain('<Password>sup3rs3cret</Password>');
        expect(xml).toContain('<User>informz</User>');
        // The easy-to-get-wrong bit: id is an ATTRIBUTE, the brand NAME is the element text.
        expect(xml).toContain('<Brand id="1234">My Brand</Brand>');
        expect(xml).toContain('<Grid type="subscriber">');
    });

    it('emits offset paging as StartRow/NumberOfRows plus the SortField they require', () => {
        const xml = connector().BuildGridRequestDocument(AUTH, [
            {
                GridType: 'subscriber', Conditions: [], ReturnFields: ['subscriber_id', 'email_address'],
                SortField: 'subscriber_id', SortOrder: 'asc', StartRow: 1000, NumberOfRows: 1000,
            },
        ]);
        expect(xml).toContain('<SortField order="asc">subscriber_id</SortField>');
        expect(xml).toContain('<StartRow>1000</StartRow>');
        expect(xml).toContain('<NumberOfRows>1000</NumberOfRows>');
        expect(xml).toContain('<DataElement>email_address</DataElement>');
    });

    it('XML-escapes values rather than letting them break the document', () => {
        const xml = connector().BuildGridRequestDocument(
            { ...AUTH, BrandName: 'Ben & Jerry <Test>' },
            [{ GridType: 'subscriber', Conditions: [], ReturnFields: [], SortField: null, SortOrder: 'asc', StartRow: null, NumberOfRows: null }],
        );
        expect(xml).toContain('Ben &amp; Jerry &lt;Test&gt;');
        expect(xml).not.toContain('Ben & Jerry <Test>');
    });
});

// ─── Credential scrubbing (security-critical) ──────────────────────────────

describe('ScrubDocument', () => {
    it('redacts the whole credential triple from a RAW document', () => {
        const xml = connector().BuildGridRequestDocument(AUTH, [
            { GridType: 'subscriber', Conditions: [], ReturnFields: [], SortField: null, SortOrder: 'asc', StartRow: null, NumberOfRows: null },
        ]);
        const scrubbed = connector().ScrubDocument(xml);
        expect(scrubbed).not.toContain('sup3rs3cret');
        expect(scrubbed).not.toContain('informz</User>');
        expect(scrubbed).not.toContain('1234');
        expect(scrubbed).not.toContain('My Brand');
        // Structure survives so a scrubbed document is still diagnosable.
        expect(scrubbed).toContain('<Password>***</Password>');
        expect(scrubbed).toContain('<Grid type="subscriber">');
    });

    it('ALSO redacts the XML-ESCAPED form the document takes inside the SOAP envelope', () => {
        // This is the form actually on the wire. If only the raw form were scrubbed, a handler that
        // attached the outbound envelope would leak the entire credential triple.
        const doc = connector().BuildGridRequestDocument(AUTH, [
            { GridType: 'subscriber', Conditions: [], ReturnFields: [], SortField: null, SortOrder: 'asc', StartRow: null, NumberOfRows: null },
        ]);
        const envelope = connector().BuildSoapEnvelope(AUTH, doc);
        const scrubbed = connector().ScrubDocument(envelope);
        expect(scrubbed).not.toContain('sup3rs3cret');
        expect(scrubbed).not.toContain('My Brand');
    });
});

// ─── Response parsing ──────────────────────────────────────────────────────

describe('ParseGridRecords', () => {
    it('parses one row per <Record>, keyed by the Field @element attribute', () => {
        const rows = connector().ParseGridRecords(SUBSCRIBER_GRID_XML, 'subscriber');
        expect(rows).toHaveLength(2);
        expect(rows[0].subscriber_id).toBe('1001');
        expect(rows[0].email_address).toBe('ada@example.org');
        expect(rows[1].subscriber_id).toBe('1002');
    });

    it('maps an empty <Field/> to null rather than an empty string', () => {
        // The distinction matters downstream: '' would overwrite a real value on upsert, null does not.
        const rows = connector().ParseGridRecords(SUBSCRIBER_GRID_XML, 'subscriber');
        expect(rows[1].modified_date).toBeNull();
    });

    it('returns no rows for a grid type the document does not carry', () => {
        expect(connector().ParseGridRecords(SUBSCRIBER_GRID_XML, 'mailing')).toHaveLength(0);
    });
});

// ─── Fault classification ──────────────────────────────────────────────────

describe('ClassifyFault', () => {
    it('maps credential / IP-allowlist / brand faults to CONFIGURATION_ERROR', () => {
        const c = connector();
        // Higher Logic validates credentials against a REGISTERED IP; that is an operator
        // provisioning problem, never a transient one, so it must not be retried.
        expect(c.ClassifyFault('InvalidIPAddress', 'ip not registered')).toBe('CONFIGURATION_ERROR');
        expect(c.ClassifyFault('NotValidUser', 'bad credentials')).toBe('CONFIGURATION_ERROR');
        expect(c.ClassifyFault('BrandNotFound', 'unknown brand')).toBe('CONFIGURATION_ERROR');
    });

    it('maps malformed-document faults to VALIDATION_ERROR', () => {
        const c = connector();
        expect(c.ClassifyFault('InvalidDocument', 'bad xml')).toBe('VALIDATION_ERROR');
        expect(c.ClassifyFault('UnknownAction', 'no such action')).toBe('VALIDATION_ERROR');
    });

    it('maps ItemNotFound to MATCH_RESOLUTION_ERROR', () => {
        expect(connector().ClassifyFault('ItemNotFound', 'no such subscriber')).toBe('MATCH_RESOLUTION_ERROR');
    });
});

describe('InformzRequestError', () => {
    it('carries the classified sync code alongside the transport status', () => {
        const err = new InformzRequestError('boom', 500, 'NotValidUser', undefined, 'CONFIGURATION_ERROR');
        expect(err).toBeInstanceOf(Error);
        expect(err.Status).toBe(500);
        expect(err.FaultCode).toBe('NotValidUser');
        expect(err.SyncCode).toBe('CONFIGURATION_ERROR');
    });
});
