#!/usr/bin/env node
/**
 * Bill.com catalog extractor.
 *
 * Builds `metadata/integration/.billcom.integration.json` from BILL's published OpenAPI, which every
 * doc page embeds in its `.md` twin. Fields are EXTRACTED, never hand-transcribed — hand-transcription
 * bypasses the vendor contract and is how catalogs silently drift from the API.
 *
 * Usage:  node scripts/extract-catalog.mjs [--out <path>]
 *
 * Deterministic: object UUIDs are derived by UUIDv5 from a stable namespace + object/field name, so
 * re-running produces identical primary keys and the metadata stays re-pushable.
 */

import { createHash } from 'node:crypto';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';

const DOC = (op) => `https://developer.bill.com/reference/${op}.md`;

/** Stable namespace so UUIDs never change between runs. */
const NS = 'b111c0m-cata-log0-0000-memberjunction';

/**
 * Objects to extract. Everything here is verified against the published spec:
 *  - `listOp` supplies the response DTO whose properties become the field set.
 *  - Write columns are only declared where the spec documents that operation.
 *  - `updatedTime` supports gt/gte/lt/lte on both invoices and receivable-payments → incremental.
 *
 * Deliberately absent: credit-memos (refunds are descoped — bc-aidp-next-golive#51) and every AP
 * object (`bills`, `/v3/payments`, vendors). The AR/AP split is enforced by ID prefix: AR is
 * customers `0cu`, invoices `00e`, receivable-payments `0rp`; AP payments are `stp`.
 */
const OBJECTS = [
  {
    name: 'customers',
    displayName: 'Customers',
    description: 'AR customers billed through BILL. ID prefix 0cu.',
    category: 'Accounts Receivable',
    listOp: 'listcustomers',
    dto: 'CustomerResponseDto',
    apiPath: '/v3/customers',
    incremental: true,
    watermark: 'updatedTime',
    write: {
      create: { path: '/v3/customers', method: 'POST' },
      // Customers update via PATCH — invoices use PUT. Asymmetric per object; a global default breaks one.
      update: { path: '/v3/customers/{id}', method: 'PATCH' },
    },
  },
  {
    name: 'invoices',
    displayName: 'Invoices',
    description:
      'AR invoices issued to customers. ID prefix 00e. Cancellation is POST /v3/invoices/{id}/archive ' +
      '(idempotent, reversed by /restore) — InvoiceStatus has no VOID/CANCELED value, so cancellation ' +
      'is the separate `archived` boolean and must NOT be modelled as a status transition.',
    category: 'Accounts Receivable',
    listOp: 'listinvoices',
    dto: 'InvoiceResponseDto',
    apiPath: '/v3/invoices',
    incremental: true,
    watermark: 'updatedTime',
    write: {
      create: { path: '/v3/invoices', method: 'POST' },
      update: { path: '/v3/invoices/{id}', method: 'PUT' },
    },
    // BILL's read and write DTOs disagree on the customer reference in BOTH name and shape:
    // InvoiceResponseDto returns a flat string `customerId`, while InvoiceCreateRequestDto REQUIRES a
    // nested `customer` OBJECT (`InvoiceCustomer`, e.g. {"id":"0cu…"}). Fields are derived from the
    // response DTO, so without this the connector sends `customerId` and BILL rejects every create.
    // Both halves were found only by live sandbox writes: sending `customerId` returns 400 "customer:
    // The customer field is required", and sending `customer` as a bare string returns 400 "Cannot
    // construct instance of ...InvoiceCustomer". Neither is reachable from the mock suite or a read probe.
    writeShape: {
      readOnly: ['customerId'],
      additional: [
        {
          name: 'customer',
          type: 'json',
          required: true,
          description:
            'Customer the invoice is issued to, as an InvoiceCustomer object — {"id":"0cu…"}, NOT a ' +
            'bare ID string. Write-only: BILL returns the same value flattened to `customerId` on read.',
        },
      ],
    },
    configuration: {
      archivePath: '/v3/invoices/{invoiceId}/archive',
      archiveMethod: 'POST',
      restorePath: '/v3/invoices/{invoiceId}/restore',
      archiveNote:
        'Cancel = archive. Idempotent — archiving an archived invoice is a no-op. `archived` is ' +
        'filterable and the default archived-inclusion behaviour is undocumented, so filter explicitly.',
      recordPaymentPath: '/v3/invoices/record-payment',
      recordPaymentNote: 'Records a payment received OUTSIDE BILL (may serve the manual-check path).',
    },
  },
  {
    name: 'receivable-payments',
    displayName: 'Receivable Payments',
    description:
      'Payments received from customers. ID prefix 0rp — distinct from AP vendor payments (stp). ' +
      'invoicePayments[] links one payment to MANY invoices, so a consuming Payment record must model ' +
      'a collection, not a single invoice FK. No v3 endpoint transitions a 0rp payment to VOID/CANCELED.',
    category: 'Accounts Receivable',
    listOp: 'listreceivablepayments',
    dto: 'ReceivablePaymentResponseDto',
    apiPath: '/v3/receivable-payments',
    incremental: true,
    watermark: 'updatedTime',
    write: {
      // "Charge a customer" — pulls funds. Requires authorizedToCharge + a customer bank account.
      create: { path: '/v3/receivable-payments', method: 'POST' },
    },
    configuration: {
      chargePrerequisite:
        'POST /v3/customers/{customerId}/charge-authorization must have set authorizedToCharge=true, ' +
        'and a customer bank account must exist.',
      detectionNote:
        'Payment detection is poll-authoritative. BILL publishes NO payment-received webhook event; ' +
        'the only AR events are invoice.created/updated/archived/restored, and invoice.updated carries ' +
        'no 0rp payment ID.',
    },
  },
];

/** UUIDv5-style deterministic id (SHA-1 of namespace + name, RFC-4122 v5 bit-twiddling). */
function stableUuid(name) {
  const h = createHash('sha1').update(NS).update(name).digest();
  const b = Buffer.from(h.subarray(0, 16));
  b[6] = (b[6] & 0x0f) | 0x50;
  b[8] = (b[8] & 0x3f) | 0x80;
  const hex = b.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`.toUpperCase();
}

/**
 * Extracts the embedded OpenAPI `components.schemas` map from a doc page.
 *
 * Walks forward from the `{` that OPENS the schemas object. An earlier version walked back from
 * `"components"` to the nearest preceding `{`, which lands mid-structure (the preceding token is
 * `},`) and yields unparseable slices.
 */
function extractSchemas(text) {
  const compIdx = text.indexOf('"components"');
  if (compIdx === -1) return {};
  const schemasIdx = text.indexOf('"schemas"', compIdx);
  if (schemasIdx === -1) return {};
  const open = text.indexOf('{', schemasIdx);
  if (open === -1) return {};

  let depth = 0;
  let inString = false;
  let escaped = false;
  for (let i = open; i < text.length; i++) {
    const ch = text[i];
    if (escaped) { escaped = false; continue; }
    if (ch === '\\') { escaped = true; continue; }
    if (ch === '"') { inString = !inString; continue; }
    if (inString) continue;
    if (ch === '{') depth++;
    else if (ch === '}') {
      depth--;
      if (depth === 0) {
        try {
          return JSON.parse(text.slice(open, i + 1));
        } catch (err) {
          throw new Error(`schemas block did not parse: ${err instanceof Error ? err.message : String(err)}`);
        }
      }
    }
  }
  return {};
}

/**
 * Derives the row DTO from the list envelope (`ListResponseDto_<DTO>_`) rather than trusting a
 * hardcoded name — the envelope is the contract, so this cannot drift.
 */
function deriveRowDto(schemas, fallback) {
  const envelope = Object.keys(schemas).find((k) => /^ListResponseDto_.+_$/.test(k));
  if (envelope) {
    const inner = envelope.replace(/^ListResponseDto_/, '').replace(/_$/, '');
    if (schemas[inner]) return inner;
  }
  return fallback;
}

/** Maps an OpenAPI property to the MJ IntegrationObjectField Type vocabulary. */
function mapType(prop) {
  if (!prop || typeof prop !== 'object') return { type: 'string', length: null };
  if (prop.$ref || prop.allOf) return { type: 'json', length: null };
  switch (prop.type) {
    case 'integer': return { type: 'int', length: null };
    case 'number': return { type: 'decimal', length: null };
    case 'boolean': return { type: 'bit', length: null };
    case 'array':
    case 'object': return { type: 'json', length: null };
    case 'string':
      if (prop.format === 'date') return { type: 'date', length: null };
      if (prop.format === 'date-time') return { type: 'datetime', length: null };
      if (Array.isArray(prop.enum)) return { type: 'string', length: 100 };
      return { type: 'string', length: prop.maxLength ?? 255 };
    default: return { type: 'string', length: 255 };
  }
}

async function fetchDoc(op) {
  const res = await fetch(DOC(op));
  if (!res.ok) throw new Error(`fetch ${op}: HTTP ${res.status}`);
  return res.text();
}

function buildFields(schema, objName) {
  const props = schema?.properties ?? {};
  const required = new Set(schema?.required ?? []);
  const out = [];
  let seq = 1;
  for (const [propName, prop] of Object.entries(props)) {
    const { type, length } = mapType(prop);
    // `id` is the vendor primary key on every AR object.
    const isPk = propName === 'id';
    // Server-computed fields — writing them is meaningless and the API ignores or rejects them.
    const readOnly = isPk || ['createdTime', 'updatedTime', 'totalAmount', 'dueAmount'].includes(propName);
    let description = typeof prop?.description === 'string' ? prop.description : '';
    if (Array.isArray(prop?.enum)) {
      const enumNote = ` Values: ${prop.enum.join(' | ')}.`;
      description = (description + enumNote).trim();
    }
    // Description is length-capped in the DB; truncate rather than fail the push.
    if (description.length > 255) description = `${description.slice(0, 252)}...`;
    out.push({
      fields: {
        Name: propName,
        DisplayName: propName.replace(/([A-Z])/g, ' $1').replace(/^./, (c) => c.toUpperCase()).trim(),
        Description: description || null,
        Type: type,
        Length: length,
        AllowsNull: !required.has(propName) && !isPk,
        IsRequired: required.has(propName),
        IsReadOnly: readOnly,
        IsUniqueKey: isPk,
        IsPrimaryKey: isPk,
        Status: 'Active',
        Sequence: seq++,
        IntegrationObjectID: '@parent:ID',
      },
      primaryKey: { ID: stableUuid(`${objName}.${propName}`) },
    });
  }
  return out;
}

/**
 * Reconcile the response-derived field list with the vendor's WRITE shape.
 *
 * Fields are extracted from the `<X>ResponseDto`, which is correct for reads and for the many fields
 * BILL names identically in both directions. Where the create/update DTO diverges, the response name
 * is demoted to read-only and the write name is added — so each direction carries the name the vendor
 * actually accepts, instead of one name that is right for only half the traffic.
 *
 * Divergences are declared per object rather than inferred, because a name that merely *looks* absent
 * from a request DTO is more often an unwritable server-computed field than a rename.
 */
function applyWriteShape(fields, spec) {
  const shape = spec.writeShape;
  if (!shape) return fields;

  for (const name of shape.readOnly ?? []) {
    const target = fields.find((f) => f.fields.Name === name);
    if (!target) throw new Error(`writeShape.readOnly names '${name}', absent from ${spec.name} response DTO`);
    target.fields.IsReadOnly = true;
  }

  let seq = fields.length + 1;
  for (const extra of shape.additional ?? []) {
    if (fields.some((f) => f.fields.Name === extra.name)) {
      throw new Error(`writeShape.additional '${extra.name}' already exists on ${spec.name}`);
    }
    const description = extra.description && extra.description.length > 255
      ? `${extra.description.slice(0, 252)}...`
      : extra.description ?? null;
    fields.push({
      fields: {
        Name: extra.name,
        DisplayName: extra.name.replace(/([A-Z])/g, ' $1').replace(/^./, (c) => c.toUpperCase()).trim(),
        Description: description,
        Type: extra.type,
        Length: extra.length ?? null,
        AllowsNull: !extra.required,
        IsRequired: Boolean(extra.required),
        IsReadOnly: false,
        IsUniqueKey: false,
        IsPrimaryKey: false,
        Status: 'Active',
        Sequence: seq++,
        IntegrationObjectID: '@parent:ID',
      },
      primaryKey: { ID: stableUuid(`${spec.name}.${extra.name}`) },
    });
  }
  return fields;
}

function buildObject(spec, schemas) {
  const dtoName = deriveRowDto(schemas, spec.dto);
  const schema = schemas[dtoName];
  if (!schema) {
    const available = Object.keys(schemas).filter((k) => k.endsWith('ResponseDto')).slice(0, 8);
    throw new Error(
      `DTO ${dtoName} not found in ${spec.listOp} spec. Candidates: ${available.join(', ') || '(none)'}`
    );
  }
  const fields = applyWriteShape(buildFields(schema, spec.name), spec);
  if (fields.length === 0) throw new Error(`no fields extracted for ${spec.name}`);

  const w = spec.write ?? {};
  const io = {
    Name: spec.name,
    DisplayName: spec.displayName,
    Description: spec.description.length > 255 ? `${spec.description.slice(0, 252)}...` : spec.description,
    Category: spec.category,
    APIPath: spec.apiPath,
    ResponseDataKey: 'results',
    PaginationType: 'Cursor',
    SupportsPagination: true,
    DefaultPageSize: 100,
    SupportsIncrementalSync: spec.incremental,
    IncrementalWatermarkField: spec.incremental ? spec.watermark : null,
    SupportsWrite: Boolean(w.create || w.update || w.delete),
    Status: 'Active',
    Configuration: {
      idPrefixNote: spec.description,
      pagination: {
        mode: 'opaque-cursor',
        params: { pageSize: 'max', cursor: 'page' },
        maxPageSize: 100,
        terminationRule:
          'Terminate on ABSENCE of nextPage. An empty results[] with nextPage present still means continue.',
        defaultDisagreement: 'Concepts page says max defaults to 100; endpoint refs say 20. Always send it.',
      },
      filterSyntax: 'filters={field}:{op}:{value}, comma-joined for AND. Ops: eq ne gt gte lt lte in nin sw.',
      ...(spec.configuration ?? {}),
    },
    IntegrationID: '@parent:ID',
  };

  if (w.create) {
    io.CreateAPIPath = w.create.path;
    io.CreateMethod = w.create.method;
    io.CreateBodyShape = 'flat';
    io.CreateBodyKey = null;
    io.CreateIDLocation = 'body';
  }
  if (w.update) {
    io.UpdateAPIPath = w.update.path;
    io.UpdateMethod = w.update.method;
    io.UpdateBodyShape = 'flat';
    io.UpdateBodyKey = null;
    io.UpdateIDLocation = 'path';
  }
  // No delete: BILL archives invoices rather than deleting, and customers/payments have no delete verb.

  return {
    fields: io,
    relatedEntities: { 'MJ: Integration Object Fields': fields },
    primaryKey: { ID: stableUuid(`object.${spec.name}`) },
  };
}

/**
 * Emits `src/generated/objects.ts` — the same object/field set the catalog declares, in the shape
 * `GetIntegrationObjects()` returns.
 *
 * Actions are GENERATED from this by MJ's `ActionMetadataGenerator` (one Action per applicable verb).
 * Emitting it from the same extraction run is what keeps the Action surface and the sync catalog from
 * drifting apart — hand-maintaining a second copy is how they diverge.
 */
function emitObjectsModule(specs, extracted) {
  const objects = specs.map((spec, i) => {
    const io = extracted[i].fields;
    const fields = extracted[i].relatedEntities['MJ: Integration Object Fields'].map((f) => ({
      Name: f.fields.Name,
      DisplayName: f.fields.DisplayName,
      Description: f.fields.Description ?? undefined,
      Type: f.fields.Type,
      IsRequired: f.fields.IsRequired,
      IsReadOnly: f.fields.IsReadOnly,
      IsPrimaryKey: f.fields.IsPrimaryKey,
    }));
    return {
      Name: io.Name,
      DisplayName: io.DisplayName,
      Description: spec.description.length > 255 ? `${spec.description.slice(0, 252)}...` : spec.description,
      SupportsWrite: io.SupportsWrite,
      Fields: fields,
    };
  });

  return `// GENERATED by scripts/extract-catalog.mjs — DO NOT EDIT BY HAND.
// Regenerate with: node scripts/extract-catalog.mjs
//
// Source of truth for BOTH the sync catalog (metadata/integration/) and Action generation
// (GetIntegrationObjects -> ActionMetadataGenerator). Extracted from BILL's published OpenAPI.

import type { IntegrationObjectInfo } from '@memberjunction/integration-engine';

export const BILLCOM_OBJECTS: IntegrationObjectInfo[] = ${JSON.stringify(objects, null, 4)};
`;
}

async function main() {
  const outArg = process.argv.indexOf('--out');
  const outPath = resolve(
    outArg !== -1 ? process.argv[outArg + 1] : 'metadata/integration/.billcom.integration.json'
  );

  const objects = [];
  for (const spec of OBJECTS) {
    process.stderr.write(`fetching ${spec.listOp}… `);
    const schemas = extractSchemas(await fetchDoc(spec.listOp));
    const obj = buildObject(spec, schemas);
    const n = obj.relatedEntities['MJ: Integration Object Fields'].length;
    process.stderr.write(`${spec.name}: ${n} fields\n`);
    objects.push(obj);
  }

  const doc = [
    {
      fields: {
        Name: 'Bill.com',

        Description:
          'Bill.com (BILL) v3 Connect API — accounts receivable. Session-based auth; 3 concurrent ' +
          'requests per developer key per organization.',
        ClassName: '@memberjunction/connector-bill-com',
        ImportPath: '@memberjunction/connector-bill-com',
        NavigationBaseURL: 'https://gateway.stage.bill.com/connect/v3/',
        BatchMaxRequestCount: 100,
        BatchRequestWaitTime: 1,
        CredentialTypeID: '@lookup:MJ: Credential Types.Name=Bill.com Session',
        Configuration: {
          AuthFlow: 'session-login',
          AuthFlowNote:
            'POST /login with username, password, organizationId, devKey returns an opaque sessionId, ' +
            'carried with devKey as headers. Sessions expire after 35 MINUTES OF INACTIVITY (sliding) ' +
            'with NO refresh mechanism — re-login is the only recovery. Logins are capped at 200/hour, ' +
            'so the session must be cached and reused, never acquired per request.',
          Concurrency:
            '3 simultaneous requests per developer key per organization (BDC_1322). 20,000 requests/hour ' +
            '(BDC_1144). Concurrency, not rate, is the binding constraint.',
          Environments: {
            sandbox: 'https://gateway.stage.bill.com/connect/v3',
            production: 'https://gateway.prod.bill.com/connect/v3',
          },
          RefundNote:
            'No AR refund endpoint exists in v3, /v3/orders does not exist, and negative invoices are ' +
            'unsupported. The sanctioned reversing document is a credit memo (ledger-only; no cash ' +
            'movement). Descoped — see bc-aidp-next-golive#51.',
        },
      },
      relatedEntities: { 'MJ: Integration Objects': objects },
      primaryKey: { ID: stableUuid('integration.billcom') },
    },
  ];

  mkdirSync(dirname(outPath), { recursive: true });
  writeFileSync(outPath, `${JSON.stringify(doc, null, 2)}\n`);
  const total = objects.reduce((a, o) => a + o.relatedEntities['MJ: Integration Object Fields'].length, 0);
  process.stderr.write(`\nwrote ${outPath}\n  ${objects.length} objects, ${total} fields\n`);

  const tsPath = resolve('src/generated/objects.ts');
  mkdirSync(dirname(tsPath), { recursive: true });
  writeFileSync(tsPath, emitObjectsModule(OBJECTS, objects));
  process.stderr.write(`wrote ${tsPath}\n`);
}

main().catch((err) => {
  process.stderr.write(`\nEXTRACT FAILED: ${err instanceof Error ? err.message : String(err)}\n`);
  process.exit(1);
});
