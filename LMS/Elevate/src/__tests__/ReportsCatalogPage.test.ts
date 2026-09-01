import { describe, it, expect } from 'vitest';
import { parseReportsCatalog } from '../ReportsCatalogPage.js';

/**
 * The fixture is the SHAPE of a real Elevate site's `/api/reports` page, reduced to two resources.
 * Structure — the div-per-resource, the "Resource <name>" heading, the Fields table, the Relations
 * table — is copied verbatim from a live site, because that structure is the entire contract: this
 * is HTML the vendor never promised as an API, so a test written against an idealised shape would
 * prove nothing about the page we actually parse.
 */
const PAGE = `
<html><body>
  <div id="resource-nav"><ul><li><a href="#user">user</a></li></ul></div>
  <div id="productRegistration">
    <h3 class="well well-small">Resource productRegistration</h3>
    <h5>Fields</h5>
    <table class="table table-condensed table-bordered">
      <tr><th>Name</th><th>Description</th></tr>
      <tr> <td>id</td> <td>ID</td> </tr>
      <tr> <td>amount_discounted</td> <td>Amount discounted</td> </tr>
      <tr> <td>transaction_at</td> <td>Transaction Date &amp; Time</td> </tr>
    </table>
    <h5>Relations</h5>
    <table class="table">
      <tr><th>Name</th><th>Description</th></tr>
      <tr> <td>user</td> <td>User</td> </tr>
      <tr> <td>product</td> <td>Product</td> </tr>
      <tr> <td>total_revenue</td> <td>Revenue</td> </tr>
    </table>
  </div>
  <div id="user">
    <h3 class="well well-small">Resource user</h3>
    <h5>Fields</h5>
    <table>
      <tr><th>Name</th><th>Description</th></tr>
      <tr> <td>member_id</td> <td>Member ID</td> </tr>
      <tr> <td>email</td> <td>Email</td> </tr>
    </table>
  </div>
  <div id="product">
    <h3 class="well well-small">Resource product</h3>
    <h5>Fields</h5>
    <table>
      <tr><th>Name</th><th>Description</th></tr>
      <tr> <td>title</td> <td>Title</td> </tr>
    </table>
  </div>
</body></html>`;

describe('parseReportsCatalog', () => {
    it('reads every documented resource with its fields and descriptions', () => {
        const cat = parseReportsCatalog(PAGE);
        expect(cat?.map(r => r.Name).sort()).toEqual(['product', 'productRegistration', 'user']);
        const pr = cat!.find(r => r.Name === 'productRegistration')!;
        expect(pr.Fields.map(f => f.Name)).toEqual(['id', 'amount_discounted', 'transaction_at']);
        expect(pr.Fields[2].Description).toBe('Transaction Date & Time');
    });

    it('keeps the header row out of the field list', () => {
        const cat = parseReportsCatalog(PAGE);
        expect(cat!.every(r => r.Fields.every(f => f.Name !== 'Name'))).toBe(true);
    });

    // The Relations table mixes relation tags, target resource names and prose labels in the same
    // two columns, so a cell is only a relation if it names a resource the page itself documents.
    // `total_revenue` sits in that table and is not a resource.
    it('resolves relations only to resources the page documents', () => {
        const pr = parseReportsCatalog(PAGE)!.find(r => r.Name === 'productRegistration')!;
        expect(pr.Relations).toEqual(['product', 'user']);
    });

    it('does not let the relations table leak into the field list', () => {
        const pr = parseReportsCatalog(PAGE)!.find(r => r.Name === 'productRegistration')!;
        expect(pr.Fields.map(f => f.Name)).not.toContain('user');
    });

    it('ignores divs that carry an id but are not resource blocks', () => {
        expect(parseReportsCatalog(PAGE)!.map(r => r.Name)).not.toContain('resource-nav');
    });

    // THE GATE. A page that parses to something not containing what we already know this vendor has
    // is a page whose shape changed; half-believing it is worse than ignoring it.
    it('discards the whole parse when a known resource is absent', () => {
        expect(parseReportsCatalog(PAGE, ['productRegistration', 'earnedCredit'])).toBeNull();
    });

    it('accepts the parse when every known resource is present', () => {
        expect(parseReportsCatalog(PAGE, ['productRegistration', 'user'])).not.toBeNull();
    });

    it.each([
        ['empty', ''],
        ['not html', 'contact your support rep'],
        ['an auth wall', '<html><body><h1>Sign in</h1></body></html>'],
        ['divs with no resource heading', '<div id="a"><table><tr><td>x</td><td>y</td></tr></table></div>'],
    ])('returns null for %s rather than guessing', (_label, html) => {
        expect(parseReportsCatalog(html)).toBeNull();
    });
});
