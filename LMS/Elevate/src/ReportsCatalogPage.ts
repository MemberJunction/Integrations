/**
 * The per-tenant resource catalog Cadmium Elevate actually publishes.
 *
 * This connector was built on the premise that Elevate "publishes no describe endpoint", so the
 * hand-written metadata was the only truth. That premise is wrong. Every Elevate site serves a
 * catalog of ITS OWN resources at `<siteUrl>/api/reports` — the same URL the Report API posts to,
 * fetched with GET instead. It needs no API key, and the vendor's own prose on that page is the
 * documented answer to "what can I query": *"In the docs area for each resource below, you will
 * find Relations"*. There is no JSON alternative; this page is what Cadmium provides.
 *
 * It is HTML, not an API, so everything here is deliberately defensive:
 *
 *   - The parse is ADDITIVE ONLY. Nothing it returns may remove or deactivate a declared object —
 *     `DiscoveryIsAuthoritative` stays false. A scraped page can be wrong in ways that look
 *     confident, and the cost of a wrong "absent" is deleting real metadata.
 *   - It is SANITY-GATED: the result is discarded wholesale unless it contains resources we already
 *     know exist. A page that parsed to something unrecognisable is a page whose shape changed, and
 *     half-believing it is worse than ignoring it.
 *   - Every failure is silent-and-fall-back, never fatal. A deployment that gates this page behind
 *     auth, disables it, or serves a different template gets exactly today's behaviour: the
 *     declared catalog.
 *
 * Only the ONE observed shape is parsed, and it is matched strictly rather than loosely, so a
 * different template fails the gate instead of yielding plausible nonsense:
 *
 *     <div id="productRegistration">
 *       <h3 ...>Resource productRegistration</h3>
 *       <h5>Fields</h5>
 *       <table> <tr><th>Name</th><th>Description</th></tr>
 *               <tr><td>id</td><td>ID</td></tr> ... </table>
 *       <h5>Relations</h5>
 *       <table> ... </table>
 *     </div>
 */

/** One field as the catalog page documents it. */
export interface CatalogField {
    /** Wire name, exactly as the page spells it — this is what goes in the `fields` selector. */
    Name: string;
    /** The page's human label for the field, if it gave one. */
    Description?: string;
}

/** One resource as the catalog page documents it. */
export interface CatalogResource {
    /** Wire value for the request body's `resource` field, e.g. `productRegistration`. */
    Name: string;
    Fields: CatalogField[];
    /**
     * Resource names this one declares a built-in relationship with. The vendor's Relations table
     * mixes relation tags, target resource names and prose labels in the same columns, so this is
     * the INTERSECTION of that table's cells with the set of real resource names on the page —
     * a name that is not itself a documented resource cannot be a relation target.
     */
    Relations: string[];
}

/** Strip tags and collapse whitespace in one cell. */
function cellText(html: string): string {
    return html.replace(/<[^>]*>/g, '').replace(/&amp;/g, '&').replace(/&nbsp;/g, ' ').trim();
}

/**
 * Parse the catalog page. Returns `null` when the page is not the shape we know — the caller then
 * keeps the declared catalog. Never throws.
 */
export function parseReportsCatalog(html: string, knownResources: readonly string[] = []): CatalogResource[] | null {
    try {
        if (!html || html.length === 0) return null;
        // Split on the per-resource divs. A resource block runs until the next one starts.
        const blocks = [...html.matchAll(/<div id="([A-Za-z][A-Za-z0-9_]*)"\s*>([\s\S]*?)(?=<div id="[A-Za-z][A-Za-z0-9_]*"\s*>|$)/g)];
        if (blocks.length === 0) return null;

        const parsed: CatalogResource[] = [];
        for (const [, name, body] of blocks) {
            // The heading is what distinguishes a RESOURCE block from any other div that happens to
            // carry an id (the page's nav, layout wrappers, etc.).
            if (!new RegExp(`Resource\\s+${name}\\b`).test(body)) continue;

            const fieldsSection = body.split(/>\s*Relations\s*</)[0];
            const fields: CatalogField[] = [];
            for (const [, rawName, rawDesc] of fieldsSection.matchAll(/<tr>\s*<td>([\s\S]*?)<\/td>\s*<td>([\s\S]*?)<\/td>\s*<\/tr>/g)) {
                const fieldName = cellText(rawName);
                // A field name has to be usable as a wire selector; the header row and any prose row
                // are rejected by that alone.
                if (!/^[A-Za-z][A-Za-z0-9_.]*$/.test(fieldName)) continue;
                const description = cellText(rawDesc);
                fields.push(description ? { Name: fieldName, Description: description } : { Name: fieldName });
            }
            if (fields.length === 0) continue;

            const relationCells: string[] = [];
            const relIdx = body.search(/>\s*Relations\s*</);
            if (relIdx >= 0) {
                for (const [, cell] of body.slice(relIdx).matchAll(/<td>([\s\S]*?)<\/td>/g)) {
                    const text = cellText(cell);
                    if (/^[A-Za-z][A-Za-z0-9_]*$/.test(text)) relationCells.push(text);
                }
            }
            parsed.push({ Name: name, Fields: fields, Relations: relationCells });
        }
        if (parsed.length === 0) return null;

        // Relations resolve only against real resources on this same page.
        const names = new Set(parsed.map(r => r.Name));
        for (const r of parsed) {
            r.Relations = [...new Set(r.Relations.filter(n => n !== r.Name && names.has(n)))].sort();
        }

        // THE GATE. If the page does not describe the resources we already know this vendor has,
        // it is not the page we think it is, and every conclusion drawn from it is suspect.
        if (knownResources.length > 0) {
            const missing = knownResources.filter(k => !names.has(k));
            if (missing.length > 0) return null;
        }
        return parsed;
    } catch {
        return null;
    }
}
