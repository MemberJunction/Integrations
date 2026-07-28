---
'@memberjunction/connector-yourmembership': patch
---

Give every writable YourMembership catalog object a primary key — or withdraw the write it cannot
honor without one. 45 of the connector's 104 writable objects were keyless; this is the largest
single block of the repo-wide writable-no-PK backlog.

A writable `IntegrationObject` with no `IsPrimaryKey` field derives a **keyless entity**. On Postgres,
MJ's save audit-wrapper then emits an empty record identifier and every save fails with
`syntax error at or near ","`, while fetch keeps succeeding — so the object reads green and persists
nothing.

Evidence throughout is the vendor's **own live, unauthenticated OpenAPI 2.0 document**, published by
the YM ServiceStack host at `https://ws.yourmembership.com/openapi` (297 paths, 656 definitions),
together with its generated DTOs at `https://ws.yourmembership.com/types/typescript`. Every route and
parameter cited below is read from that document — nothing is inferred and no key is invented.

**Stamped (4)** — real, addressable records that get the vendor's own identifier:

| Object | Key | Vendor evidence |
| --- | --- | --- |
| `Members` | `ProfileID` | `GET /Ams/{ClientID}/MemberList` → `MemberListResponse.Members: MemberResponse[]`, whose first member is `ProfileID: number`. The sibling write DTO (`Members extends Person`) addresses a member as `id`, but that field is never populated by this object's declared read door — keying on it would key on an always-null column. |
| `CustomPages` | `PageID` | `PageID` is present on all four declared routes (`GET`/`PUT`/`POST`/`DELETE /Ams/{ClientID}/CustomPages`) and the response echoes `PageIDUsedByAnotherPage`. |
| `OrganizationPosts` | `PostId` | Required path token of `PUT`/`DELETE /Ams/{ClientID}/OrganizationPosts/{PostId}` — which is exactly the URL the connector's `UpdateRecord`/`DeleteRecord` build. |
| `SMSCampaigns` | `CampaignID` | Required path token of `PUT`/`DELETE /Ams/{ClientID}/SMSCampaigns/{CampaignId}` — same generic-URL match. |

**Withdrawn (41)**, in four groups:

- **(a) RPC command payloads — a verb, not a record (21).** `ConvertToMemberRequest`,
  `EventRegistrationAttendance`, `EventSessionAttendanceRequest`, `FilesUpload`, `HtmlSanitization`,
  the eight `Informz*` shapes, `InvoicePayments`, `PeopleBulkDetachRequest`,
  `ResourceManagerFilesUpload`, `RssBuilder`, `StoreProductBulkStatus`, `StoreProductBulkStatusAll`,
  `StoreProductSequence`, `StoreProductUpdate`. Each is a single POST/PUT route with no collection and
  no item route, and its declared fields are the call's *arguments* plus its *outcome* — e.g.
  `HtmlSanitization` is `Body` in, `SanitizedBody` out; `InformzFindGroupRequest` is `GroupName` in,
  `Exist` out; `StoreProductUpdate`'s one field is a packed product/stock-level list. There is nothing
  stored to key on.

- **(b) Real records the connector's generic write URL cannot address (12).**
  `DonationHistoryCancelAutoBill`, `EventAlias`, `MarkupRender`, `MessageFolders`,
  `NotificationSubscription`, `NotificationUpdate`, `PhotoComments`, `ProductsDto`,
  `RegistrationSessionRequest`, `SendTestNotification`, `WallPostFirst`, `WallPosts`. The connector
  builds every write URL as `/Ams/{ClientID}/{ObjectName}` (create) or
  `/Ams/{ClientID}/{ObjectName}/{ExternalID}` (update, delete), with no way to interpolate a parent id.
  So although e.g. `MessageFolders` is genuinely keyed on `FolderId`, the vendor addresses it at
  `/Member/{MemberID}/MessageFolders/{FolderId}` and the request would still 404 — a key would be
  necessary but not sufficient. `ProductsDto` fails the same test for a different reason: its route
  segment is `Products`, not the object name. Re-enabling this group needs parent-scoped write URL
  support in the connector plus a live round-trip to verify it, deliberately out of scope here.

- **(c) Client-level singletons with no scalar identifier (2).** `BrandingConfig` is the client's one
  branding configuration, addressed with no item id — and the catalog row declares **zero** fields, so
  there is nothing to key on. `ContentAreas` has no scalar id either: its DTO is
  `{ AreaType, VersionID, Revert, VersionLabel, VersionNotes, Publish, ContentArea }` where
  `ContentArea` is a nested object and `VersionID` is a version, not an identity.

- **(d) Auth / infrastructure RPC not on the record surface at all (6).** `Auth` is the
  session-bootstrap exchange the connector already performs internally in `GetSession`. `GetToken`,
  `GetAccessToken` and `OIDCGetAccessToken` live under `/OAuth/…`, entirely outside
  `/Ams/{ClientID}/`. `MemberPasswordReset` is at `/Ams/MemberPasswordReset` with **no** `{ClientID}`
  segment, and `UnblockCardRequest` at `/Ams/FraudPrevention/{ClientID}/UnblockCard` — neither is
  reachable by the connector's URL shape.

Reads are unaffected on every withdrawn object. Metadata and the delta migration move together in both
dialects; the `V202607111614` seed is untouched, so no existing UUID is re-minted and no Flyway
checksum breaks.

Repo-wide, writable objects with no primary key drop from 92 to 47 — and every one of the remaining 47
is already fixed on an open PR (re:Members/Neon/Cvent/PheedLoop/MagnetMail on #110, ConstantContact on
#107, Blackbaud/Hivebrite on #109, NetForum on #111, Stripe/Totara/Eventbrite on #108, Mailchimp on
#96), so this closes the backlog.

Separately noted, not changed here: **none** of this connector's 104 writable objects sets
`SupportsCreate`, `SupportsUpdate` or `SupportsDelete`, so no per-operation write is enabled anywhere
in the catalog today. Turning any of them on is a behavioral claim that needs a live round-trip, so
this change deliberately only fixes record identity.
