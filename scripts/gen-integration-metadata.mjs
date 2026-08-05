#!/usr/bin/env node
/**
 * Projects a connector's TS object catalog into its mj-sync metadata JSON.
 *
 * WHY THIS EXISTS. Every connector states its schema twice: once as a TS table the connector answers
 * `DiscoverObjects`/`DiscoverFields` from (needed because a --base connector has no vendor API to
 * introspect, and because discovery must work before metadata is seeded), and once as
 * `metadata/integration/.<slug>.integration.json`, the mj-sync records the seed migration ships. The
 * shipped public connectors maintain both by hand, with nothing checking that they agree. At ~180
 * fields that drift is a certainty and it is SILENT: the created columns simply stop matching the
 * emitted records, and the sync lands nulls rather than failing.
 *
 * So the TS table is the authority and this generates the JSON from it.
 *
 *   node scripts/gen-integration-metadata.mjs            # write the JSON
 *   node scripts/gen-integration-metadata.mjs --check    # fail if it is stale (CI)
 *
 * Reads the .ts catalog directly — Node 24 strips types natively, so there is no build step between
 * editing the catalog and regenerating.
 */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const CHECK = process.argv.includes('--check');

/**
 * The connectors in this repo. One entry per package; the Integration-level fields live here rather
 * than in the TS catalog because they describe the integration, not its schema.
 */
const CONNECTORS = [
    {
        dir: 'Marketing/GA4',
        catalog: 'src/GA4Objects.ts',
        exportName: 'GA4_OBJECTS',
        outFile: 'metadata/integration/.ga4.integration.json',
        integration: {
            Name: 'Google Analytics 4',
            Description:
                'Google Analytics 4 connector over the Data API v1beta. Syncs three defined reports \u2014 daily page performance, and campaign traffic at both campaign and utm_content grain \u2014 keyed by date plus their dimension tuple. Read-only, service-account credential.',
            ClassName: '@memberjunction/connector-ga4',
            ImportPath: '@memberjunction/connector-ga4',
            NavigationBaseURL: 'https://analytics.google.com',
            CredentialTypeID: '@lookup:MJ: Credential Types.Name=Google Service Account',
            Icon: 'fa-brands fa-google',
        },
    },
];

/**
 * mj-sync record wrapper.
 *
 * `stamp` carries the `primaryKey`/`sync` block that `mj sync push` writes back into the file. Those
 * are NOT regenerable — the UUID is the record's permanent identity, and the seed migration hardcodes
 * it. Dropping them on a regen would mint a fresh UUID for every object and field on every run, so
 * the same connector would seed different IDs into every environment. They are carried through from
 * the previous file, keyed by name (see `stampsFrom`).
 *
 * Key order matters only for `--check` stability: it must match what `mj sync push` emits, which is
 * fields → relatedEntities → primaryKey → sync.
 */
const rec = (fields, relatedEntities, stamp) => {
    const out = { fields };
    if (relatedEntities) out.relatedEntities = relatedEntities;
    if (stamp?.primaryKey) out.primaryKey = stamp.primaryKey;
    if (stamp?.sync) out.sync = stamp.sync;
    return out;
};

/**
 * Index the stamps of an already-pushed file so a regen can carry them forward.
 *
 * Keyed by name rather than by position: renaming or reordering the catalog must not silently
 * reassign one field's identity to another. A record whose name is new simply has no stamp, and
 * `mj sync push` assigns it a fresh UUID — which is exactly right.
 */
function stampsFrom(path) {
    if (!existsSync(path)) return { integration: undefined, byKey: new Map() };
    let doc;
    try {
        doc = JSON.parse(readFileSync(path, 'utf-8'));
    } catch {
        return { integration: undefined, byKey: new Map() };
    }
    const byKey = new Map();
    const root = Array.isArray(doc) ? doc[0] : undefined;
    const take = (r) => (r?.primaryKey || r?.sync ? { primaryKey: r.primaryKey, sync: r.sync } : undefined);
    for (const o of root?.relatedEntities?.['MJ: Integration Objects'] ?? []) {
        byKey.set(o.fields.Name, take(o));
        for (const f of o.relatedEntities?.['MJ: Integration Object Fields'] ?? []) {
            byKey.set(`${o.fields.Name}.${f.fields.Name}`, take(f));
        }
    }
    return { integration: take(root), byKey };
}

/**
 * One IntegrationObjectField record.
 *
 * `Length`, `Precision` and `Scale` are emitted ONLY for the types that use them. Emitting a stray
 * `Length` on a decimal, or a `Precision` on a string, is the kind of thing the schema builder
 * ignores silently — so keep the record to exactly what the declared type means.
 */
function fieldRecord(f, sequence, stamp) {
    const fields = {
        IntegrationObjectID: '@parent:ID',
        Name: f.Name,
        DisplayName: f.DisplayName,
        Description: f.Description,
        Type: f.Type,
    };
    if (f.Length !== undefined) fields.Length = f.Length;
    if (f.Precision !== undefined) fields.Precision = f.Precision;
    if (f.Scale !== undefined) fields.Scale = f.Scale;
    Object.assign(fields, {
        IsPrimaryKey: f.IsPrimaryKey,
        IsUniqueKey: f.IsUniqueKey,
        IsRequired: f.IsRequired,
        IsReadOnly: f.IsReadOnly,
        AllowsNull: f.AllowsNull,
        Sequence: sequence,
        Status: 'Active',
    });
    return rec(fields, undefined, stamp);
}

function objectRecord(o, sequence, stamps) {
    return rec(
        {
            IntegrationID: '@parent:ID',
            Name: o.Name,
            DisplayName: o.DisplayName,
            Description: o.Description,
            Category: o.Category,
            APIPath: o.APIPath,
            // Declared per object, not assumed.
            SupportsPagination: o.PaginationType !== 'None',
            PaginationType: o.PaginationType,
            SupportsIncrementalSync: o.SupportsIncrementalSync,
            IncrementalWatermarkField: o.IncrementalWatermarkField ?? null,
            SupportsWrite: false,
            Sequence: sequence,
            Status: 'Active',
        },
        {
            'MJ: Integration Object Fields': o.Fields.map((f, n) =>
                fieldRecord(f, n + 1, stamps.byKey.get(`${o.Name}.${f.Name}`))
            ),
        },
        stamps.byKey.get(o.Name)
    );
}

/**
 * Deploy-blocker: Description is nvarchar(255) on ALL THREE record levels and over-length fails the
 * push with a rollback. Checking only two of the three is how a 330-char Integration description got
 * all the way to `mj sync push` before anything complained.
 */
function assertDescriptions(objects, label, integrationDescription) {
    const tooLong = [];
    if (integrationDescription !== undefined && integrationDescription.length > 255) {
        tooLong.push(`${label} (Integration) (${integrationDescription.length})`);
    }
    for (const o of objects) {
        if (o.Description.length > 255) tooLong.push(`${label}.${o.Name} (${o.Description.length})`);
        for (const f of o.Fields) {
            if (f.Description.length > 255) {
                tooLong.push(`${label}.${o.Name}.${f.Name} (${f.Description.length})`);
            }
        }
    }
    if (tooLong.length > 0) {
        throw new Error(`Description exceeds 255 chars:\n  ${tooLong.join('\n  ')}`);
    }
}

/** Duplicate field names within one object silently collide on push. */
function assertNoDuplicateNames(objects, label) {
    for (const o of objects) {
        const seen = new Set();
        for (const f of o.Fields) {
            const key = f.Name.toLowerCase();
            if (seen.has(key)) throw new Error(`${label}.${o.Name}: duplicate field '${f.Name}'`);
            seen.add(key);
        }
    }
    const objSeen = new Set();
    for (const o of objects) {
        const key = o.Name.toLowerCase();
        if (objSeen.has(key)) throw new Error(`${label}: duplicate object '${o.Name}'`);
        objSeen.add(key);
    }
}

let stale = 0;
for (const c of CONNECTORS) {
    const catalogPath = join(ROOT, c.dir, c.catalog);
    if (!existsSync(catalogPath)) {
        console.error(`missing catalog: ${catalogPath}`);
        process.exit(1);
    }
    const mod = await import(catalogPath);
    const objects = mod[c.exportName];
    if (!Array.isArray(objects)) {
        console.error(`${c.catalog} does not export ${c.exportName} as an array`);
        process.exit(1);
    }

    assertDescriptions(objects, c.integration.Name, c.integration.Description);
    assertNoDuplicateNames(objects, c.integration.Name);

    const outPath = join(ROOT, c.dir, c.outFile);
    const stamps = stampsFrom(outPath);

    const doc = [
        rec(
            c.integration,
            { 'MJ: Integration Objects': objects.map((o, n) => objectRecord(o, n + 1, stamps)) },
            stamps.integration
        ),
    ];
    // No trailing newline: `mj sync push` rewrites this file in place without one, and matching it
    // byte-for-byte is what lets `--check` pass straight after a push instead of reporting a
    // one-character diff that looks like real drift.
    const text = JSON.stringify(doc, null, 2);

    const fieldCount = objects.reduce((a, o) => a + o.Fields.length, 0);
    if (CHECK) {
        const current = existsSync(outPath) ? readFileSync(outPath, 'utf-8') : '';
        if (current !== text) {
            console.error(`STALE: ${c.dir}/${c.outFile} — run: node scripts/gen-integration-metadata.mjs`);
            stale++;
        } else {
            console.log(`ok    ${c.dir}/${c.outFile} (${objects.length} objects, ${fieldCount} fields)`);
        }
    } else {
        writeFileSync(outPath, text, 'utf-8');
        console.log(`wrote ${c.dir}/${c.outFile} (${objects.length} objects, ${fieldCount} fields)`);
    }
}
process.exit(stale > 0 ? 1 : 0);
