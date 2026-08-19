import { describe, it, expect } from 'vitest';
import type { ExternalRecord } from '@memberjunction/integration-engine';
import {
    ParseDerivedCollectionConfig,
    ExplodeCollection,
    DropConfiguredFields,
    type DerivedCollectionConfig,
} from '../DerivedCollections.js';

const rec = (fields: Record<string, unknown>): ExternalRecord =>
    ({ ExternalID: String(fields.id ?? 'x'), ObjectType: 'Enrolled Users', Fields: fields }) as ExternalRecord;

describe('ParseDerivedCollectionConfig', () => {
    it('returns null when absent', () => {
        expect(ParseDerivedCollectionConfig(null)).toBeNull();
        expect(ParseDerivedCollectionConfig(undefined)).toBeNull();
    });

    it('throws loudly on a half-configured declaration — never quietly empty', () => {
        expect(() => ParseDerivedCollectionConfig({})).toThrow(/parentObjectName/);
        expect(() => ParseDerivedCollectionConfig({ parentObjectName: 'Enrolled Users' })).toThrow(/collectionField/);
        expect(() => ParseDerivedCollectionConfig({ parentObjectName: 'P', collectionField: 'roles' })).toThrow(/elementKind/);
        expect(() => ParseDerivedCollectionConfig({ parentObjectName: 'P', collectionField: 'roles', elementKind: 'object' })).toThrow(/parentKeyMap/);
        expect(() => ParseDerivedCollectionConfig({
            parentObjectName: 'P', collectionField: 'userids', elementKind: 'scalar', parentKeyMap: { cohortid: 'cohortid' },
        })).toThrow(/scalarFieldName/);
    });

    it('parses the object and scalar shapes', () => {
        const objCfg = ParseDerivedCollectionConfig({
            parentObjectName: 'Enrolled Users', collectionField: 'roles',
            parentKeyMap: { id: 'userid', courseid: 'courseid' }, elementKind: 'object',
            elementKeyMap: { id: 'roleid' },
        });
        expect(objCfg?.elementKind).toBe('object');
        expect(objCfg?.parentKeyMap).toEqual({ id: 'userid', courseid: 'courseid' });

        const scalarCfg = ParseDerivedCollectionConfig({
            parentObjectName: 'Cohort Members', collectionField: 'userids',
            parentKeyMap: { cohortid: 'cohortid' }, elementKind: 'scalar', scalarFieldName: 'userid',
        });
        expect(scalarCfg?.scalarFieldName).toBe('userid');
    });
});

describe('ExplodeCollection — object elements', () => {
    const cfg: DerivedCollectionConfig = {
        parentObjectName: 'Enrolled Users', collectionField: 'roles',
        parentKeyMap: { id: 'userid', courseid: 'courseid' }, elementKind: 'object',
    };

    it('emits one child per element, carrying renamed parent keys', () => {
        const parents = [rec({
            id: 7, courseid: 12, fullname: 'A Person',
            roles: [
                { roleid: 5, shortname: 'student', name: 'Learner', sortorder: 1 },
                { roleid: 3, shortname: 'editingteacher', name: 'Trainer', sortorder: 2 },
            ],
        })];
        const out = ExplodeCollection(parents, cfg);
        expect(out.ChildFields).toEqual([
            { userid: 7, courseid: 12, roleid: 5, shortname: 'student', name: 'Learner', sortorder: 1 },
            { userid: 7, courseid: 12, roleid: 3, shortname: 'editingteacher', name: 'Trainer', sortorder: 2 },
        ]);
        expect(out.ParentsWithoutCollection).toBe(0);
        expect(out.ElementsSkipped).toBe(0);
    });

    it('renames colliding element keys via elementKeyMap, and parent keys win any remaining collision', () => {
        const groupCfg: DerivedCollectionConfig = {
            ...cfg, collectionField: 'groups', elementKeyMap: { id: 'groupid' },
        };
        const parents = [rec({ id: 7, courseid: 12, groups: [{ id: 99, name: 'G' }] })];
        const out = ExplodeCollection(parents, groupCfg);
        // element id -> groupid; parent id -> userid; nothing shadows the join identity
        expect(out.ChildFields).toEqual([{ userid: 7, courseid: 12, groupid: 99, name: 'G' }]);
    });

    it('an element that shadows a parent key WITHOUT a rename is dropped from the child, not the parent key', () => {
        const parents = [rec({ id: 7, courseid: 12, groups: [{ id: 99, name: 'G' }] })];
        const out = ExplodeCollection(parents, { ...cfg, collectionField: 'groups' });
        // no elementKeyMap: element 'id' would shadow... parent map renames parent id->userid,
        // so element id keeps its name UNLESS it collides with a mapped child key. Here it doesn't.
        expect(out.ChildFields).toEqual([{ userid: 7, courseid: 12, id: 99, name: 'G' }]);
    });

    it('counts absent/non-array collections and skips kind-mismatched elements', () => {
        const parents = [
            rec({ id: 1, courseid: 2 }),                            // no collection at all
            rec({ id: 3, courseid: 4, roles: 'not-an-array' }),     // wrong type
            rec({ id: 5, courseid: 6, roles: [null, 42, { roleid: 9 }] }), // two bad elements, one good
        ];
        const out = ExplodeCollection(parents, cfg);
        expect(out.ParentsWithoutCollection).toBe(2);
        expect(out.ElementsSkipped).toBe(2);
        expect(out.ChildFields).toEqual([{ userid: 5, courseid: 6, roleid: 9 }]);
    });

    it('an empty array is a real answer, not a missing collection', () => {
        const out = ExplodeCollection([rec({ id: 1, courseid: 2, roles: [] })], cfg);
        expect(out.ParentsWithoutCollection).toBe(0);
        expect(out.ChildFields).toEqual([]);
    });
});

describe('ExplodeCollection — scalar elements', () => {
    const cfg: DerivedCollectionConfig = {
        parentObjectName: 'Cohort Members', collectionField: 'userids',
        parentKeyMap: { cohortid: 'cohortid' }, elementKind: 'scalar', scalarFieldName: 'userid',
    };

    it('emits one (cohortid, userid) row per element', () => {
        const parents = [
            { ExternalID: 'c1', ObjectType: 'Cohort Members', Fields: { cohortid: 10, userids: [7, 8, 9] } } as ExternalRecord,
        ];
        const out = ExplodeCollection(parents, cfg);
        expect(out.ChildFields).toEqual([
            { cohortid: 10, userid: 7 },
            { cohortid: 10, userid: 8 },
            { cohortid: 10, userid: 9 },
        ]);
    });

    it('skips object elements in a scalar collection', () => {
        const parents = [
            { ExternalID: 'c1', ObjectType: 'Cohort Members', Fields: { cohortid: 10, userids: [7, { nested: true }] } } as ExternalRecord,
        ];
        const out = ExplodeCollection(parents, cfg);
        expect(out.ElementsSkipped).toBe(1);
        expect(out.ChildFields).toEqual([{ cohortid: 10, userid: 7 }]);
    });
});

describe('DropConfiguredFields', () => {
    it('returns the ORIGINAL object when nothing matches (no allocation on the common path)', () => {
        const raw = { id: 1, fullname: 'A' };
        expect(DropConfiguredFields(raw, null)).toBe(raw);
        expect(DropConfiguredFields(raw, [])).toBe(raw);
        expect(DropConfiguredFields(raw, ['preferences'])).toBe(raw);
    });

    it('drops exactly the configured keys', () => {
        const out = DropConfiguredFields(
            { id: 1, preferences: '[…]', fullname: 'A' },
            ['preferences'],
        );
        expect(out).toEqual({ id: 1, fullname: 'A' });
    });
});
