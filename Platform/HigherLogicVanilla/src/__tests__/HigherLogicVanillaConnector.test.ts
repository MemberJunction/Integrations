import { describe, it, expect } from 'vitest';
import type { MJCompanyIntegrationEntity, MJIntegrationObjectEntity } from '@memberjunction/core-entities';
import type { UserInfo } from '@memberjunction/core';
import type { RESTAuthContext, RESTResponse } from '@memberjunction/integration-engine';
import {
  HigherLogicVanillaConnector,
  parseVanillaWindowCursor,
  formatVanillaWindowCursor,
  initialVanillaDateWindow,
  nextVanillaDateWindow,
  formatVanillaBoundedDateFilter,
} from '../HigherLogicVanillaConnector.js';

class TestableVanillaConnector extends HigherLogicVanillaConnector {
  public requestedUrls: string[] = [];
  public sleepDurations: number[] = [];
  public mockResponses: Array<{ status: number; body: unknown; headers?: Record<string, string> }> = [];
  public mockObject: Partial<MJIntegrationObjectEntity> = {
    ID: 'obj-discussions',
    Name: 'Discussion',
    ExternalName: 'Discussion',
    APIPath: '/discussions',
    ResponseDataKey: null,
    DefaultPageSize: 2,
    SupportsPagination: true,
    PaginationType: 'PageNumber',
    SupportsIncrementalSync: true,
    IncrementalWatermarkField: 'dateUpdated',
  };

  protected override GetCachedObject(_integrationID: string, _objectName: string): MJIntegrationObjectEntity {
    return this.mockObject as MJIntegrationObjectEntity;
  }

  protected override GetCachedFields(_objectID: string) {
    return [];
  }

  protected override async Sleep(ms: number): Promise<void> {
    this.sleepDurations.push(ms);
  }

  protected override async MakeHTTPRequest(
    _auth: RESTAuthContext,
    url: string,
    _method: string,
    _headers: Record<string, string>
  ): Promise<RESTResponse> {
    this.requestedUrls.push(url);
    const next = this.mockResponses.shift() ?? { status: 200, body: [], headers: {} };
    const headers: Record<string, string> = {};
    for (const [k, v] of Object.entries(next.headers ?? {})) {
      headers[k.toLowerCase()] = v;
    }
    (this as unknown as { lastResponseHeaders: Record<string, string> }).lastResponseHeaders = headers;
    return {
      Status: next.status,
      Body: next.body,
      Headers: headers,
    };
  }
}

function makeCompanyIntegration(config: Record<string, unknown>): MJCompanyIntegrationEntity {
  return {
    ID: 'ci-vanilla-1',
    IntegrationID: 'int-vanilla-1',
    CredentialID: null,
    Configuration: JSON.stringify({
      token: 'pat-test-token',
      communityUrl: 'https://community.example.org',
      ...config,
    }),
  } as unknown as MJCompanyIntegrationEntity;
}

const mockUser = { ID: 'u-1' } as unknown as UserInfo;

describe('HigherLogicVanillaConnector', () => {
  it('exposes the integration name and default rate limit policy', () => {
    const connector = new HigherLogicVanillaConnector();
    expect(connector.IntegrationName).toBe('higherlogic-vanilla');
    expect(connector.RateLimitPolicy).toEqual({ TokensPerSec: 5, Burst: 10 });
    expect(connector.MaxConcurrencyHint).toBe(3);
  });

  describe('Sliding Date-Window Helpers & Cursor Serialization', () => {
    it('round-trips VanillaWindowCursor in v1|<Today>|<From>|<To>|<InnerPage>|<ScopeKey> format', () => {
      const encoded = formatVanillaWindowCursor({
        Today: '2026-03-01',
        From: '2026-01-01',
        To: '2026-01-30',
        InnerPage: 4,
        ScopeKey: 'Discussion',
      });
      expect(encoded).toBe('v1|2026-03-01|2026-01-01|2026-01-30|4|Discussion');
      const parsed = parseVanillaWindowCursor(encoded);
      expect(parsed).toEqual({
        Today: '2026-03-01',
        From: '2026-01-01',
        To: '2026-01-30',
        InnerPage: 4,
        ScopeKey: 'Discussion',
      });
      expect(parseVanillaWindowCursor('invalid')).toBeNull();
    });

    it('computes initial and subsequent date windows up to Today', () => {
      const now = new Date('2026-02-15T12:00:00Z');
      const w1 = initialVanillaDateWindow(
        { enabled: true, earliestBackfillDate: '2026-01-01', windowSizeDays: 30 },
        null,
        now
      );
      expect(w1).toEqual({
        From: '2026-01-01',
        To: '2026-01-30',
        Today: '2026-02-15',
      });

      const w2 = nextVanillaDateWindow(w1, { windowSizeDays: 30 });
      expect(w2).toEqual({
        From: '2026-01-31',
        To: '2026-02-15',
        Today: '2026-02-15',
      });

      const w3 = nextVanillaDateWindow(w2!, { windowSizeDays: 30 });
      expect(w3).toBeNull();
    });

    it('formats bounded Vanilla API v2 date range filters', () => {
      const filter = formatVanillaBoundedDateFilter('dateUpdated', {
        From: '2026-01-01',
        To: '2026-01-30',
        Today: '2026-02-15',
      });
      expect(decodeURIComponent(filter)).toBe('dateUpdated=[2026-01-01,2026-01-30]');
    });
  });

  describe('Metered Migration Pacing & Windowed FetchChanges', () => {
    it('applies migrationPacing overrides and traverses inner pages and date windows', async () => {
      const connector = new TestableVanillaConnector();
      const ci = makeCompanyIntegration({
        migrationPacing: {
          tokensPerSec: 2,
          burst: 3,
          maxConcurrency: 1,
          minDelayBetweenRequestsMs: 400,
          checkpointPerWindow: true,
        },
        dateWindowing: {
          enabled: true,
          earliestBackfillDate: '2026-01-01',
          windowSizeDays: 30,
        },
      });

      // Page 1 of Window 1 (returns Link rel="next" -> more pages in window 1)
      connector.mockResponses.push({
        status: 200,
        body: [
          { discussionID: 101, name: 'First', dateUpdated: '2026-01-10T00:00:00Z' },
          { discussionID: 102, name: 'Second', dateUpdated: '2026-01-12T00:00:00Z' },
        ],
        headers: {
          link: '<https://community.example.org/api/v2/discussions?page=2&limit=2>; rel="next"',
        },
      });

      const batch1 = await connector.FetchChanges({
        CompanyIntegration: ci,
        ObjectName: 'Discussion',
        BatchSize: 2,
        ContextUser: mockUser,
      });

      expect(connector.RateLimitPolicy).toEqual({ TokensPerSec: 2, Burst: 3 });
      expect(connector.MaxConcurrencyHint).toBe(1);
      expect(connector.sleepDurations).toEqual([400]);
      expect(decodeURIComponent(connector.requestedUrls[0])).toContain(
        '/api/v2/discussions?page=1&limit=2&dateUpdated=[2026-01-01,2026-01-30]'
      );
      expect(batch1.HasMore).toBe(true);
      expect(batch1.NextCursor).toMatch(/\|2026-01-01\|2026-01-30\|2\|Discussion$/);

      // Page 2 of Window 1 (no Link header and < pageSize -> window 1 exhausted -> advances to Window 2)
      connector.mockResponses.push({
        status: 200,
        body: [{ discussionID: 103, name: 'Third', dateUpdated: '2026-01-25T00:00:00Z' }],
        headers: {},
      });

      const batch2 = await connector.FetchChanges({
        CompanyIntegration: ci,
        ObjectName: 'Discussion',
        BatchSize: 2,
        CurrentCursor: batch1.NextCursor,
        ContextUser: mockUser,
      });

      expect(decodeURIComponent(connector.requestedUrls[1])).toContain(
        '/api/v2/discussions?page=2&limit=2&dateUpdated=[2026-01-01,2026-01-30]'
      );
      expect(batch2.HasMore).toBe(true);
      expect(batch2.NextCursor).toMatch(/\|2026-01-31\|2026-03-01\|1\|Discussion$/);
      expect(batch2.NewWatermarkValue).toBe('2026-01-30T23:59:59Z');
    });
  });
});

