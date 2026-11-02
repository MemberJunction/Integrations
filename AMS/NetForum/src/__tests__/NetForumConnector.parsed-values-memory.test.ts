import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import type { RESTResponse } from '@memberjunction/integration-engine';
import type { MJCompanyIntegrationEntity } from '@memberjunction/core-entities';
import type { UserInfo } from '@memberjunction/core';
import { NetForumConnector } from '../NetForumConnector.js';
import { type FakeDefinition, type World, fetchObject, internals, makeConnector } from './netforum-fake-xweb.js';
import { ExternalTextMB, LargeResponse, PAGE_MB } from './retained-text.js';

/**
 * Values the connector parses out of a response must not keep the response in memory.
 *
 * The connector reads XML with regular expressions. In V8 a capture or substring of 13 or more characters points into
 * the string it came from, so a kept value keeps the whole response. The engine keeps record IDs for the whole entity
 * map and the connector keeps parsed definitions for its whole life.
 *
 * No mock on the value path records its calls (vi.fn / vi.spyOn): a recorded call would itself keep the values.
 */

/** The connector members these tests replace or read. */
interface DefinitionInternals {
    Authenticate(ci: MJCompanyIntegrationEntity, cu: UserInfo): Promise<{ Config: { BaseURL: string }; Token: string }>;
    SendSoap(action: string, url: string, args: Record<string, unknown>, token: string): Promise<RESTResponse>;
    DefinitionFor(ci: MJCompanyIntegrationEntity, cu: UserInfo, objectName: string): Promise<FakeDefinition | null>;
}

const envelope = (body: string): string =>
    `<?xml version="1.0"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body>${body}</soap:Body></soap:Envelope>`;

/** A GetQuery response with one Individual row whose key is `key`. */
const getQueryPage = (key: string): RESTResponse => ({
    Status: 200,
    Headers: {},
    Body: LargeResponse(envelope(
        `<GetQueryResponse><GetQueryResult><Results><Result><ind_key>${key}</ind_key><ind_first_name>Ann</ind_first_name>` +
        `</Result></Results></GetQueryResult></GetQueryResponse>`)),
});

/** A GetQueryDefinition response for `objectName` with one column, `<objectName>_key_column`. */
const definitionPage = (objectName: string): RESTResponse => ({
    Status: 200,
    Headers: {},
    Body: LargeResponse(envelope(
        `<GetQueryDefinitionResponse><GetQueryDefinitionResult><lst_mdt_name>${objectName}_main_table</lst_mdt_name>` +
        `<Column><mdc_name>${objectName}_key_column</mdc_name><mdc_table_name>${objectName}_main_table</mdc_table_name>` +
        `<mdc_data_type>uniqueidentifier</mdc_data_type><mdc_description>Primary Key</mdc_description></Column>` +
        `</GetQueryDefinitionResult></GetQueryDefinitionResponse>`)),
});

describe('NetForumConnector — parsed values do not keep the response in memory', () => {
    const original = { operatorRoot: NetForumConnector.OperatorRoot, learnedRoot: NetForumConnector.LearnedRoot, warn: console.warn };
    let root = '';

    beforeEach(() => {
        root = mkdtempSync(join(tmpdir(), 'nf-test-'));
        NetForumConnector.OperatorRoot = root;
        NetForumConnector.LearnedRoot = null;
        console.warn = () => undefined;
    });

    afterEach(() => {
        NetForumConnector.OperatorRoot = original.operatorRoot;
        NetForumConnector.LearnedRoot = original.learnedRoot;
        console.warn = original.warn;
        rmSync(root, { recursive: true, force: true });
    });

    it('keeping the record IDs of fetched pages does not keep the pages', async () => {
        const world: World = {
            Individual: { def: { KeyColumn: 'ind_key', Columns: [['co_individual', 'ind_key'], ['co_individual', 'ind_first_name']] }, pk: 'ind_key' },
        };
        const connector = makeConnector(world, root, []);
        let page = 0;
        internals(connector).SendGetQuery = async () => getQueryPage(`individual-key-${String(++page).padStart(4, '0')}`);
        const ids: string[] = [];
        // Fetched inside a helper so the test's own frame never holds a parsed value.
        const fetchIDs = async (): Promise<void> => {
            const outcome = await fetchObject(connector, 'Individual');
            if (outcome.ok) ids.push(...outcome.r.Records.map(r => r.ExternalID));
        };

        const before = await ExternalTextMB();
        for (let i = 0; i < 10; i++) await fetchIDs();
        const kept = (await ExternalTextMB()) - before;

        expect(ids).toHaveLength(10);
        expect(ids[3]).toBe('individual-key-0004');
        expect(kept).toBeLessThan(PAGE_MB);
    });

    it('caching parsed definitions does not keep the definition responses', async () => {
        const connector = new NetForumConnector();
        const x = connector as unknown as DefinitionInternals;
        x.Authenticate = async () => ({ Config: { BaseURL: 'https://xweb.invalid' }, Token: 't' });
        x.SendSoap = async (_action, _url, args) => definitionPage(String(args.szObjectName));
        const ci = { ID: 'CI1', IntegrationID: 'I1' } as unknown as MJCompanyIntegrationEntity;
        const cu = {} as UserInfo;
        const loadDefinition = async (objectName: string): Promise<void> => { await x.DefinitionFor(ci, cu, objectName); };

        const before = await ExternalTextMB();
        for (let i = 0; i < 10; i++) await loadDefinition(`Object${i}`);
        const kept = (await ExternalTextMB()) - before;

        const cached = await x.DefinitionFor(ci, cu, 'Object3');
        expect(cached?.Columns.map(c => c.Name)).toEqual(['Object3_key_column']);
        expect(cached?.MainTable).toBe('Object3_main_table');
        expect(kept).toBeLessThan(PAGE_MB);
    });
});
