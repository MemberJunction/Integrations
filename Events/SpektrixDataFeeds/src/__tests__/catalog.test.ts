import { describe, expect, it } from 'vitest';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { CATALOG, PiiClassesFor } from '../catalog.js';
import { PII_CLASSES } from '../pii/policy.js';

const here = dirname(fileURLToPath(import.meta.url));
const METADATA = join(here, '..', '..', 'metadata', 'integration', '.spektrix-data-feeds.integration.json');

describe('catalog', () => {
    it('classifies every field with a known PII class', () => {
        for (const o of CATALOG) for (const f of o.fields) expect(PII_CLASSES, `${o.name}.${f.name}`).toContain(f.pii);
    });

    it('gives every object at least one primary key and unique field names', () => {
        for (const o of CATALOG) {
            expect(o.fields.some((f) => f.isPrimaryKey), o.name).toBe(true);
            expect(new Set(o.fields.map((f) => f.name)).size).toBe(o.fields.length);
        }
    });

    it('declares the watermark field on the incremental object only, and it exists', () => {
        for (const o of CATALOG) {
            if (o.syncStrategy === 'WatermarkIncremental') {
                expect(o.incrementalWatermarkField).not.toBeNull();
                expect(o.fields.map((f) => f.name)).toContain(o.incrementalWatermarkField);
            } else {
                expect(o.incrementalWatermarkField).toBeNull();
            }
        }
    });

    it('PiiClassesFor covers every field', () => {
        for (const o of CATALOG) expect(Object.keys(PiiClassesFor(o))).toEqual(o.fields.map((f) => f.name));
    });
});

describe('metadata/integration matches the catalog', () => {
    it.skipIf(!existsSync(METADATA))('declares the same objects, fields, keys, types and PII classes', () => {
        const [integration] = JSON.parse(readFileSync(METADATA, 'utf8')) as Array<{
            fields: Record<string, unknown>;
            relatedEntities: { 'MJ: Integration Objects': Array<{ fields: Record<string, unknown>; relatedEntities: { 'MJ: Integration Object Fields': Array<{ fields: Record<string, unknown> }> } }> };
        }>;
        expect(integration!.fields['ClassName']).toBe('SpektrixDataFeedsConnector');
        expect(integration!.fields['ImportPath']).toBe('@memberjunction/connector-spektrix-data-feeds');
        const objects = integration!.relatedEntities['MJ: Integration Objects'];
        expect(objects.map((o) => o.fields['Name'])).toEqual(CATALOG.map((o) => o.name));
        for (const o of CATALOG) {
            const io = objects.find((x) => x.fields['Name'] === o.name)!;
            expect(io.fields['SyncStrategy']).toBe(o.syncStrategy);
            expect(io.fields['IncrementalWatermarkField']).toBe(o.incrementalWatermarkField);
            expect(io.fields['APIPath']).toBe(o.apiPath);
            const iofs = io.relatedEntities['MJ: Integration Object Fields'];
            expect(iofs.map((f) => f.fields['Name'])).toEqual(o.fields.map((f) => f.name));
            for (const f of o.fields) {
                const iof = iofs.find((x) => x.fields['Name'] === f.name)!.fields;
                expect(iof['Type'], `${o.name}.${f.name}`).toBe(f.type);
                expect(iof['IsPrimaryKey'], `${o.name}.${f.name}`).toBe(f.isPrimaryKey === true);
                expect(iof['AllowsNull'], `${o.name}.${f.name}`).toBe(f.allowsNull);
                expect((iof['Configuration'] as { pii: string }).pii, `${o.name}.${f.name}`).toBe(f.pii);
            }
        }
    });
});
