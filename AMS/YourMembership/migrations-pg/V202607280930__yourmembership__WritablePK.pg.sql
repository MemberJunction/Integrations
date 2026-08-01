-- ============================================================================
-- MemberJunction PostgreSQL Migration
-- Converted from SQL Server using TypeScript conversion pipeline
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Schema
CREATE SCHEMA IF NOT EXISTS __mj;
SET search_path TO __mj, public;

-- Ensure backslashes in string literals are treated literally (not as escape sequences)
SET standard_conforming_strings = on;

-- NOTE: Earlier converter versions made INTEGER to BOOLEAN cast implicit by
-- modifying the system catalog so SS-style INSERT INTO bool_col VALUES (1)
-- would work. That modification required pg_catalog write privileges, which
-- managed PG (RDS, Aurora, Cloud SQL, Azure) does not grant. As of v5.30 all
-- bulk INSERTs are emitted with native TRUE/FALSE values directly, so the
-- cast modification is no longer needed. Removed to support managed-PG
-- installs out of the box.


-- ===================== Data (INSERT/UPDATE/DELETE) =====================

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "ID" = '9E667855-FF7E-470A-9F0A-F737D3221B27';

UPDATE "__mj"."IntegrationObject"
SET "Description" = 'Organization members with profile, contact, and membership details Primary key: ProfileID, the member identifier returned by this object''s own declared read door (GET /Ams/{ClientID}/MemberList -> MemberListResponse.Members: MemberResponse[], whose first member is ProfileID). The sibling write DTO addresses a member as id, but that field is never populated by the read door, so it would be an always-null key.'
WHERE "ID" = '13924718-72B5-4102-AF11-5F755FD90877';

-- ── stamp 2. CustomPages.PageID ──

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "ID" = 'ED9BE137-F9CB-45F9-801E-8E5CE51BEF00';

UPDATE "__mj"."IntegrationObject"
SET "Description" = 'Return a Custom Page. Primary key: PageID, present on all four declared routes (GET/PUT/POST/DELETE /Ams/{ClientID}/CustomPages) and echoed by the response as PageIDUsedByAnotherPage.'
WHERE "ID" = '53EE6EAB-FC41-48B0-B07A-040B5E5788CA';

-- ── stamp 3. OrganizationPosts.PostId ──

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "ID" = '17B04DB6-ECFC-4040-986F-CBD35431884E';

UPDATE "__mj"."IntegrationObject"
SET "Description" = 'Get a list of organization posts. Primary key: PostId, the required path token of the item routes PUT|DELETE /Ams/{ClientID}/OrganizationPosts/{PostId}.'
WHERE "ID" = 'DEB88BB5-FD06-4D30-A96C-73FC6EF6BA40';

-- ── stamp 4. SMSCampaigns.CampaignID ──

UPDATE "__mj"."IntegrationObjectField"
SET "IsPrimaryKey" = TRUE,
    "IsRequired" = TRUE,
    "AllowsNull" = FALSE
WHERE "ID" = '9CF2713F-6C2D-4EA1-B266-5152599907B5';

UPDATE "__mj"."IntegrationObject"
SET "Description" = 'Return the details of a SMS Campaign. Primary key: CampaignID, the required path token of the item routes PUT|DELETE /Ams/{ClientID}/SMSCampaigns/{CampaignId}.'
WHERE "ID" = '41A73983-6C7B-4EB8-8DCB-B4D54F73440B';

-- ── withdraw 1. ConvertToMemberRequest (a) — POST /Ams/{ClientID}/ConvertToMember ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Convert Non-member to Member, based on given Non MemberId Command payload ("Convert Non-member to Member, based on given Non MemberId"), not a record: it carries the arguments (UserName, SignupDate, MemberTypeCode, NonMemberId) plus the outcome (Success, Message). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '9B0FC36C-CC0A-49A6-82D6-E7E203FB66F3';

-- ── withdraw 2. EventRegistrationAttendance (a) — PUT /Ams/{ClientID}/EventRegistrationAttendance ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Update the Attendance flag and Date/Time for a Registration. Command payload ("Update the Attendance flag and Date/Time for a Registration"): it names a RegistrationID it does not own, and there is no collection to enumerate or item route to address. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'CB32B461-E377-44D1-840F-E0CA95CBE475';

-- ── withdraw 3. EventSessionAttendanceRequest (a) — PUT /Ams/{ClientID}/EventSessionAttendance ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Update the event session attendance Command payload ("Update the event session attendance"): arguments (RegistrantID, SessionID, AttendedSession) plus the outcome (Success, Message). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '1D51C876-12F5-464F-A413-E0122992C0BF';

-- ── withdraw 4. FilesUpload (a) — POST /Ams/{ClientID}/FilesUpload ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Upload community files. Upload command ("Upload community files"): a POST-only route with no collection, no item route and no returned identifier. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'F894FC9D-C87B-47FB-A1D8-6B1048B594F5';

-- ── withdraw 5. HtmlSanitization (a) — POST /Ams/{ClientID}/HtmlSanitization ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Return a sanitized Html A pure function, not a record: it takes Body and returns SanitizedBody. Nothing is stored, so nothing can be keyed. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'AB190EF8-5CF8-473C-B580-D1F5D1A62559';

-- ── withdraw 6. InformzBulkUploadBySearchGuidRequest (a) — POST /Ams/{ClientID}/InformzBulkUploadBySearchGuid ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Upload emails and personal data to Informz for search. Bulk-upload command ("Upload emails and personal data to Informz for search"): the two fields are its arguments (GroupName, SearchGuid). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '35E4C4E5-05E1-48EA-BA6B-F66FD73C9F28';

-- ── withdraw 7. InformzBulkUploadEventRegistrantsRequest (a) — POST /Ams/{ClientID}/InformzBulkUploadEventRegistrants ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Upload emails and personal data to Informz for event. Bulk-upload command ("Upload emails and personal data to Informz for event"): every field is a selection criterion, not a stored attribute. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '0C33672D-4F3B-49AB-8F2A-95CF79608D90';

-- ── withdraw 8. InformzBulkUploadForDuesBySearchIdRequest (a) — POST /Ams/{ClientID}/InformzBulkUploadForDuesBySearchId ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Upload emails and personal data to Informz for Dues by SearchId. Bulk-upload command: the two fields are its arguments (GroupName, SearchId). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '09F8E9AD-5132-4E54-99FB-69F60FF750E0';

-- ── withdraw 9. InformzBulkUploadForDuesRequest (a) — POST /Ams/{ClientID}/InformzBulkUploadForDues ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Upload emails and personal data to Informz for dues. Bulk-upload command: all 25 fields are dues-selection criteria (date ranges, status filters, ID exclusion lists), not attributes of a stored record. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'EDFD2461-FA3C-439F-AD8F-76B8BDEE27B4';

-- ── withdraw 10. InformzBulkUploadForOrdersBySearchIdRequest (a) — POST /Ams/{ClientID}/InformzBulkUploadForOrdersBySearchId ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Upload emails and personal data to Informz for Orders by SearchId. Bulk-upload command: the two fields are its arguments (GroupName, SearchId). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '58AF1389-D2B3-450B-A207-B23E04426CDB';

-- ── withdraw 11. InformzBulkUploadForOrdersRequest (a) — POST /Ams/{ClientID}/InformzBulkUploadForOrders ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Upload emails and personal data to Informz for orders. Bulk-upload command: all 24 fields are order-selection criteria, not attributes of a stored record. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '369753B6-28C2-4A9B-85A4-C2C4CDA756B0';

-- ── withdraw 12. InformzBulkUploadForReportsRequest (a) — POST /Ams/{ClientID}/InformzBulkUploadForReports ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Upload emails and personal data to Informz for Reports. Bulk-upload command: the two fields are its arguments (GroupName, SearchId). Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'AB868636-3094-48C3-8602-3FBFF98E604E';

-- ── withdraw 13. InformzFindGroupRequest (a) — POST /Ams/{ClientID}/InformzFindGroup ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Return whether the given group already exists. An existence query ("Return whether the given group already exists") shaped as a POST: GroupName in, Exist out. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '8AD2C811-0B3A-4339-A26F-E83A2DDE66B1';

-- ── withdraw 14. InvoicePayments (a) — POST /Ams/{ClientID}/InvoicePayments ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Apply a payment to an invoice. Command payload ("Apply a payment to an invoice"): it names the InvoiceNo it applies to, returns no payment identifier, and has no collection or item route. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '752162BD-EFC2-4459-A225-E28668755B4A';

-- ── withdraw 15. PeopleBulkDetachRequest (a) — POST /Ams/{ClientID}/PeopleBulkDetach ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Detach multiple sub accounts from master account Bulk command ("Detach multiple sub accounts from master account"): it carries a list (SubAccountIds) and the outcome (Status, Flag) — many targets, one call, no record. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '4E8BACC9-2C38-4CD9-80BF-1FB0271E1E55';

-- ── withdraw 16. ResourceManagerFilesUpload (a) — POST /Ams/{ClientID}/ResouremanagerFilesUpload ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Upload Resource manager files. Upload command ("Upload Resource manager files"): a POST-only route with no collection, no item route and no returned identifier. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '09AB5667-1595-4DAD-808F-171602715860';

-- ── withdraw 17. RssBuilder (a) — POST /Ams/{ClientID}/RssBuilder ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Returns a list of Time zones. A fetch-and-transform function, not a record: Url in, SiteContent out. Nothing is stored. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '8B6DA29C-A10C-43E3-A694-67CC0CB69CD0';

-- ── withdraw 18. StoreProductBulkStatus (a) — PUT /Ams/{ClientID}/StoreProductBulkStatus ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Update store products status in bulk. Bulk command ("Update store products status in bulk"): one call carries a list of ProductIDs plus the Status to apply to all of them. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '20CE651B-25BA-4AF3-A56F-77C547FD7955';

-- ── withdraw 19. StoreProductBulkStatusAll (a) — PUT /Ams/{ClientID}/StoreProductBulkStatusAll ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Update all store products status in bulk. Bulk command ("Update all store products status in bulk"): its fields are filters (NameFilter, CategoryId, StatusFilter) plus the Status to apply. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '02A38EB0-C9EA-4586-9FC0-73AF6FF0C592';

-- ── withdraw 20. StoreProductSequence (a) — PUT /Ams/{ClientID}/StoreProductSequence ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Set the sequence for a store product. Bulk command ("Set the sequence for a store product"): one call carries a whole ProductList for a category. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'D01C4CC7-0DEE-4AF7-ACD2-CDC712C508BF';

-- ── withdraw 21. StoreProductUpdate (a) — PUT /Ams/{ClientID}/StoreProductUpdate ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Update store products. Bulk command ("Update store products"): its single field, ProductIdStockLevelCombo, is a packed list of product/stock-level pairs. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'D81165FC-F8D7-46E9-9FCB-20E02E6424F6';

-- ── withdraw 22. DonationHistoryCancelAutoBill (b) — PUT /Ams/{ClientID}/Member/{MemberID}/DonationHistoryCancelAutoBill ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Cancel single and multiple invoice of donation. A member-scoped cancel command; the connector writes to /Ams/{ClientID}/{ObjectName}, which cannot express the /Member/{MemberID}/ segment. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '93E92665-E33A-4520-88EA-65EDB3E2A523';

-- ── withdraw 23. EventAlias (b) — GET|POST|DELETE /Ams/{ClientID}/Event/{EventId}/Alias ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Return an event''s alias. An event-scoped singleton (one alias per event) addressed under /Event/{EventId}/; the connector cannot express the parent segment. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '1E73445A-5B5F-4D89-8713-DB12E51AB833';

-- ── withdraw 24. MarkupRender (b) — GET /Ams/{ClientID}/MarkupRender/{MarkupId} (POST /MarkupRender by name) ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Render markup from MarkupId and store it in the corresponding destination (email campaign, custom page, content area, etc). A render command that stores its output elsewhere ("...and store it in the corresponding destination (email campaign, custom page, content area, etc)"); the only item route is a read. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '4167644F-B57D-4F6C-A9B5-119ADFC1AE70';

-- ── withdraw 25. MessageFolders (b) — PUT|DELETE /Ams/{ClientID}/Member/{MemberID}/MessageFolders/{FolderId} ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Return a list of message folders for a member. A genuine member-scoped record keyed on FolderId, but addressed under /Member/{MemberID}/, which the connector’s generic write URL cannot express. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '93734E95-F9C2-429C-AB94-A6B4AF49FB4E';

-- ── withdraw 26. NotificationSubscription (b) — POST /Ams/{ClientID}/Member/{MemberID}/NotificationSubscription ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Subscribe a user/device for Push Notification. A member-scoped device-subscribe command ("Subscribe a user/device for Push Notification"), addressed under a parent segment the connector cannot express. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'C3C54155-E7C1-4B23-A408-7B45D7B3FE1E';

-- ── withdraw 27. NotificationUpdate (b) — GET|PUT /Ams/{ClientID}/Notification/{NotificationID} ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Update the details of notification. A genuine record keyed on NotificationID, but the vendor addresses it under /Notification/, while the connector writes to /{ObjectName} — here the literal segment "NotificationUpdate", which is not a route. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'F1756450-18A2-4D63-A0E7-BEB283530FFD';

-- ── withdraw 28. PhotoComments (b) — POST .../Photos/{PhotoId}/Comments, DELETE .../Comments/{CommentId} ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Add a comment to a photo. A genuine record keyed on CommentId, but doubly parent-scoped (/Member/{MemberID}/Photos/{PhotoId}/), which the connector cannot express. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '77BD1DAB-C788-4519-8A76-086D95AF42E6';

-- ── withdraw 29. ProductsDto (b) — GET|PUT|POST /Ams/{ClientID}/Products, GET /Products/{id} ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Create Store Product. A genuine record keyed on ProductID, but the route segment is Products while the object is named ProductsDto — the connector writes to /{ObjectName}, i.e. /ProductsDto, which is not a route. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'A1CE7657-1C85-4930-B08D-85208CC6DAC6';

-- ── withdraw 30. RegistrationSessionRequest (b) — POST|DELETE /Ams/{ClientID}/Event/{EventID}/EventRegistrationSessions ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Assign session to event registration. An event-scoped assign command ("Assign session to event registration") carrying a list of Sessions; addressed under a parent segment the connector cannot express. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '659F1F91-9C22-46A4-B3E9-E52A6EB96721';

-- ── withdraw 31. SendTestNotification (b) — POST /Ams/{ClientID}/Notification/{NotificationID}/SendTest ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Send the Test Email Notification. A send command ("Send the Test Email Notification") scoped under a notification; nothing is created, and the parent segment is not expressible. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '4F848F28-74BC-4677-B0C8-4EF0E40E979D';

-- ── withdraw 32. WallPostFirst (b) — POST /Ams/{ClientID}/Member/{MemberID}/WallPostFirst ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Add a member''s first Post to the wall. A member-scoped POST-only command ("Add a member’s first Post to the wall") under a parent segment the connector cannot express. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '941B8F77-F7AF-4619-BDC0-BF918D0A2BFE';

-- ── withdraw 33. WallPosts (b) — POST .../Member/{MemberID}/WallPosts, DELETE .../WallPosts/{PostId} ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Add a new post to the wall. A genuine record keyed on PostId, but member-scoped under /Member/{MemberID}/, which the connector’s generic write URL cannot express. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '9366A988-3776-434A-AF4F-530EF316F868';

-- ── withdraw 34. BrandingConfig (c) — GET|PUT|DELETE /Ams/{ClientID}/BrandingConfig ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Retrieve branding configuration for the given device. The client’s single branding configuration, addressed with no item id — and this catalog row declares ZERO fields, so there is nothing to key on and nothing may be invented. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '6EA3D06C-8979-4335-AC5D-64265D2BB097';

-- ── withdraw 35. ContentAreas (c) — GET|PUT /Ams/{ClientID}/ContentAreas ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Return a content area. No scalar identifier exists: the DTO is { AreaType, VersionID, Revert, VersionLabel, VersionNotes, Publish, ContentArea } where ContentArea is a nested object, and VersionID is a version, not an identity. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '513CA6D9-6F85-4D85-97BD-675A4F4EF7A7';

-- ── withdraw 36. Auth (d) — /auth, /authenticate (ServiceStack), /Ams/Authenticate ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'The session-bootstrap exchange the connector already performs internally (GetSession): credentials in, SessionId/BearerToken out. It is not on the /Ams/{ClientID}/ record surface and is not a record. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'F1C63B99-96CE-45EA-AE2E-9045DF46D473';

-- ── withdraw 37. GetToken (d) — POST /OAuth/GetToken ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Returns the access token for either an authorization code or refresh token. An OAuth token exchange under /OAuth/, outside the /Ams/{ClientID}/ record surface entirely; its fields are grant parameters and the issued token. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = '38FB922C-B75D-475C-A061-A8F45562CF1C';

-- ── withdraw 38. GetAccessToken (d) — POST /OAuth/GetAccessToken ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Returns the access_token in exchange of AppId, AppSecret, Code/RefreshToken. Note: the key “AppSecert” has been deprecated and will be removed in a future update. An OAuth token exchange under /OAuth/, outside the /Ams/{ClientID}/ record surface entirely. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'CB3712CD-7FF7-4A10-A90E-E37CF376909E';

-- ── withdraw 39. OIDCGetAccessToken (d) — POST /OAuth/OIDC/GetAccessToken ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Returns the access token for either an authorization code or refresh token. An OIDC token exchange under /OAuth/OIDC/, outside the /Ams/{ClientID}/ record surface entirely. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'E75F9B4E-784B-426F-8972-3AD65E809EC3';

-- ── withdraw 40. MemberPasswordReset (d) — POST /Ams/MemberPasswordReset ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Send member password reset instructions to client via email. A client-less command route ("Send member password reset instructions to client via email") — there is no {ClientID} segment, so the connector’s /Ams/{ClientID}/{ObjectName} URL cannot reach it. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'FC3D8BED-02A8-4245-AC69-1D24C21D7381';

-- ── withdraw 41. UnblockCardRequest (d) — POST /Ams/FraudPrevention/{ClientID}/UnblockCard ──

UPDATE "__mj"."IntegrationObject"
SET "SupportsWrite" = FALSE,
    "Description"   = 'Unblock the Card from FraudPrevention Service A fraud-prevention command on a differently-shaped route (/Ams/FraudPrevention/{ClientID}/...); CardIdentifier in, Success/Message out. Write withdrawn: a writable object with no primary key derives a keyless entity whose saves cannot carry a record identifier. Reads are unaffected.'
WHERE "ID" = 'D0931950-E413-4576-8402-2D20CFF208F0';


-- ===================== Other =====================

-- YourMembership: the 45 writable objects that carried no primary key.
--
-- A writable IntegrationObject with no IsPrimaryKey field yields a KEYLESS derived entity. On
-- Postgres, MJ's save audit-wrapper then emits an empty record identifier and every save fails with
--     syntax error at or near ","
-- while fetch keeps succeeding — so the object reads green and persists nothing.
--
-- Evidence throughout is the vendor's OWN live, unauthenticated OpenAPI 2.0 document, published by
-- the YM ServiceStack host at https://ws.yourmembership.com/openapi (297 paths, 656 definitions),
-- together with its generated DTOs at https://ws.yourmembership.com/types/typescript. Every route
-- and parameter quoted below is read from that document.
--
-- Four of the 45 are real, addressable records and get the vendor's own identifier stamped. The
-- other 41 cannot honor a write and have it withdrawn — none is given an invented key.
--
-- ── STAMP (4) ──────────────────────────────────────────────────────────────────────────────────
--    Members              -> ProfileID
--        Primary key: ProfileID, the member identifier returned by this object's own declared read door (GET /Ams/{ClientID}/MemberList -> MemberListResponse.Members: MemberResponse[], whose first member is ProfileID). The sibling write DTO addresses a member as id, but that field is never populated by the read door, so it would be an always-null key.
--    CustomPages          -> PageID
--        Primary key: PageID, present on all four declared routes (GET/PUT/POST/DELETE /Ams/{ClientID}/CustomPages) and echoed by the response as PageIDUsedByAnotherPage.
--    OrganizationPosts    -> PostId
--        Primary key: PostId, the required path token of the item routes PUT|DELETE /Ams/{ClientID}/OrganizationPosts/{PostId}.
--    SMSCampaigns         -> CampaignID
--        Primary key: CampaignID, the required path token of the item routes PUT|DELETE /Ams/{ClientID}/SMSCampaigns/{CampaignId}.
--
-- ── WITHDRAW (41) ───────────────────────────────────────────────────────────────────────────
--
-- (a) RPC command payloads — a verb, not a record:
--    ConvertToMemberRequest                     POST /Ams/{ClientID}/ConvertToMember
--        Command payload ("Convert Non-member to Member, based on given Non MemberId"), not a record: it carries the arguments (UserName, SignupDate, MemberTypeCode, NonMemberId) plus the outcome (Success, Message).
--    EventRegistrationAttendance                PUT /Ams/{ClientID}/EventRegistrationAttendance
--        Command payload ("Update the Attendance flag and Date/Time for a Registration"): it names a RegistrationID it does not own, and there is no collection to enumerate or item route to address.
--    EventSessionAttendanceRequest              PUT /Ams/{ClientID}/EventSessionAttendance
--        Command payload ("Update the event session attendance"): arguments (RegistrantID, SessionID, AttendedSession) plus the outcome (Success, Message).
--    FilesUpload                                POST /Ams/{ClientID}/FilesUpload
--        Upload command ("Upload community files"): a POST-only route with no collection, no item route and no returned identifier.
--    HtmlSanitization                           POST /Ams/{ClientID}/HtmlSanitization
--        A pure function, not a record: it takes Body and returns SanitizedBody. Nothing is stored, so nothing can be keyed.
--    InformzBulkUploadBySearchGuidRequest       POST /Ams/{ClientID}/InformzBulkUploadBySearchGuid
--        Bulk-upload command ("Upload emails and personal data to Informz for search"): the two fields are its arguments (GroupName, SearchGuid).
--    InformzBulkUploadEventRegistrantsRequest   POST /Ams/{ClientID}/InformzBulkUploadEventRegistrants
--        Bulk-upload command ("Upload emails and personal data to Informz for event"): every field is a selection criterion, not a stored attribute.
--    InformzBulkUploadForDuesBySearchIdRequest  POST /Ams/{ClientID}/InformzBulkUploadForDuesBySearchId
--        Bulk-upload command: the two fields are its arguments (GroupName, SearchId).
--    InformzBulkUploadForDuesRequest            POST /Ams/{ClientID}/InformzBulkUploadForDues
--        Bulk-upload command: all 25 fields are dues-selection criteria (date ranges, status filters, ID exclusion lists), not attributes of a stored record.
--    InformzBulkUploadForOrdersBySearchIdRequest POST /Ams/{ClientID}/InformzBulkUploadForOrdersBySearchId
--        Bulk-upload command: the two fields are its arguments (GroupName, SearchId).
--    InformzBulkUploadForOrdersRequest          POST /Ams/{ClientID}/InformzBulkUploadForOrders
--        Bulk-upload command: all 24 fields are order-selection criteria, not attributes of a stored record.
--    InformzBulkUploadForReportsRequest         POST /Ams/{ClientID}/InformzBulkUploadForReports
--        Bulk-upload command: the two fields are its arguments (GroupName, SearchId).
--    InformzFindGroupRequest                    POST /Ams/{ClientID}/InformzFindGroup
--        An existence query ("Return whether the given group already exists") shaped as a POST: GroupName in, Exist out.
--    InvoicePayments                            POST /Ams/{ClientID}/InvoicePayments
--        Command payload ("Apply a payment to an invoice"): it names the InvoiceNo it applies to, returns no payment identifier, and has no collection or item route.
--    PeopleBulkDetachRequest                    POST /Ams/{ClientID}/PeopleBulkDetach
--        Bulk command ("Detach multiple sub accounts from master account"): it carries a list (SubAccountIds) and the outcome (Status, Flag) — many targets, one call, no record.
--    ResourceManagerFilesUpload                 POST /Ams/{ClientID}/ResouremanagerFilesUpload
--        Upload command ("Upload Resource manager files"): a POST-only route with no collection, no item route and no returned identifier.
--    RssBuilder                                 POST /Ams/{ClientID}/RssBuilder
--        A fetch-and-transform function, not a record: Url in, SiteContent out. Nothing is stored.
--    StoreProductBulkStatus                     PUT /Ams/{ClientID}/StoreProductBulkStatus
--        Bulk command ("Update store products status in bulk"): one call carries a list of ProductIDs plus the Status to apply to all of them.
--    StoreProductBulkStatusAll                  PUT /Ams/{ClientID}/StoreProductBulkStatusAll
--        Bulk command ("Update all store products status in bulk"): its fields are filters (NameFilter, CategoryId, StatusFilter) plus the Status to apply.
--    StoreProductSequence                       PUT /Ams/{ClientID}/StoreProductSequence
--        Bulk command ("Set the sequence for a store product"): one call carries a whole ProductList for a category.
--    StoreProductUpdate                         PUT /Ams/{ClientID}/StoreProductUpdate
--        Bulk command ("Update store products"): its single field, ProductIdStockLevelCombo, is a packed list of product/stock-level pairs.
--
-- (b) real records the connector’s generic write URL cannot address (parent-scoped, or the route segment differs from the object name):
--     The connector builds every write URL as /Ams/{ClientID}/{ObjectName} (create) or
--     /Ams/{ClientID}/{ObjectName}/{ExternalID} (update, delete). It has no way to interpolate a
--     parent id, so for these objects a primary key would be necessary but not sufficient — the
--     request would still 404. Re-enabling them needs parent-scoped write URL support in the
--     connector plus a live round-trip to verify it, which is deliberately out of scope here.
--    DonationHistoryCancelAutoBill              PUT /Ams/{ClientID}/Member/{MemberID}/DonationHistoryCancelAutoBill
--        A member-scoped cancel command; the connector writes to /Ams/{ClientID}/{ObjectName}, which cannot express the /Member/{MemberID}/ segment.
--    EventAlias                                 GET|POST|DELETE /Ams/{ClientID}/Event/{EventId}/Alias
--        An event-scoped singleton (one alias per event) addressed under /Event/{EventId}/; the connector cannot express the parent segment.
--    MarkupRender                               GET /Ams/{ClientID}/MarkupRender/{MarkupId} (POST /MarkupRender by name)
--        A render command that stores its output elsewhere ("...and store it in the corresponding destination (email campaign, custom page, content area, etc)"); the only item route is a read.
--    MessageFolders                             PUT|DELETE /Ams/{ClientID}/Member/{MemberID}/MessageFolders/{FolderId}
--        A genuine member-scoped record keyed on FolderId, but addressed under /Member/{MemberID}/, which the connector’s generic write URL cannot express.
--    NotificationSubscription                   POST /Ams/{ClientID}/Member/{MemberID}/NotificationSubscription
--        A member-scoped device-subscribe command ("Subscribe a user/device for Push Notification"), addressed under a parent segment the connector cannot express.
--    NotificationUpdate                         GET|PUT /Ams/{ClientID}/Notification/{NotificationID}
--        A genuine record keyed on NotificationID, but the vendor addresses it under /Notification/, while the connector writes to /{ObjectName} — here the literal segment "NotificationUpdate", which is not a route.
--    PhotoComments                              POST .../Photos/{PhotoId}/Comments, DELETE .../Comments/{CommentId}
--        A genuine record keyed on CommentId, but doubly parent-scoped (/Member/{MemberID}/Photos/{PhotoId}/), which the connector cannot express.
--    ProductsDto                                GET|PUT|POST /Ams/{ClientID}/Products, GET /Products/{id}
--        A genuine record keyed on ProductID, but the route segment is Products while the object is named ProductsDto — the connector writes to /{ObjectName}, i.e. /ProductsDto, which is not a route.
--    RegistrationSessionRequest                 POST|DELETE /Ams/{ClientID}/Event/{EventID}/EventRegistrationSessions
--        An event-scoped assign command ("Assign session to event registration") carrying a list of Sessions; addressed under a parent segment the connector cannot express.
--    SendTestNotification                       POST /Ams/{ClientID}/Notification/{NotificationID}/SendTest
--        A send command ("Send the Test Email Notification") scoped under a notification; nothing is created, and the parent segment is not expressible.
--    WallPostFirst                              POST /Ams/{ClientID}/Member/{MemberID}/WallPostFirst
--        A member-scoped POST-only command ("Add a member’s first Post to the wall") under a parent segment the connector cannot express.
--    WallPosts                                  POST .../Member/{MemberID}/WallPosts, DELETE .../WallPosts/{PostId}
--        A genuine record keyed on PostId, but member-scoped under /Member/{MemberID}/, which the connector’s generic write URL cannot express.
--
-- (c) client-level singletons / composites with no scalar identifier:
--    BrandingConfig                             GET|PUT|DELETE /Ams/{ClientID}/BrandingConfig
--        The client’s single branding configuration, addressed with no item id — and this catalog row declares ZERO fields, so there is nothing to key on and nothing may be invented.
--    ContentAreas                               GET|PUT /Ams/{ClientID}/ContentAreas
--        No scalar identifier exists: the DTO is { AreaType, VersionID, Revert, VersionLabel, VersionNotes, Publish, ContentArea } where ContentArea is a nested object, and VersionID is a version, not an identity.
--
-- (d) auth + infrastructure RPC that is not on the /Ams/{ClientID}/ record surface at all:
--    Auth                                       /auth, /authenticate (ServiceStack), /Ams/Authenticate
--        The session-bootstrap exchange the connector already performs internally (GetSession): credentials in, SessionId/BearerToken out. It is not on the /Ams/{ClientID}/ record surface and is not a record.
--    GetToken                                   POST /OAuth/GetToken
--        An OAuth token exchange under /OAuth/, outside the /Ams/{ClientID}/ record surface entirely; its fields are grant parameters and the issued token.
--    GetAccessToken                             POST /OAuth/GetAccessToken
--        An OAuth token exchange under /OAuth/, outside the /Ams/{ClientID}/ record surface entirely.
--    OIDCGetAccessToken                         POST /OAuth/OIDC/GetAccessToken
--        An OIDC token exchange under /OAuth/OIDC/, outside the /Ams/{ClientID}/ record surface entirely.
--    MemberPasswordReset                        POST /Ams/MemberPasswordReset
--        A client-less command route ("Send member password reset instructions to client via email") — there is no {ClientID} segment, so the connector’s /Ams/{ClientID}/{ObjectName} URL cannot reach it.
--    UnblockCardRequest                         POST /Ams/FraudPrevention/{ClientID}/UnblockCard
--        A fraud-prevention command on a differently-shaped route (/Ams/FraudPrevention/{ClientID}/...); CardIdentifier in, Success/Message out.
--
-- Reads are unaffected on every withdrawn object.
--
-- DELTA migration, deliberately not a re-seed: the catalog rows already exist on installed tenants,
-- so the V202607111614 seed stays untouched and applied — no existing UUID is re-minted, no Flyway
-- checksum breaks, no UQ collision. Every statement is idempotent (keyed by the seeded row ID).

-- ── stamp 1. Members.ProfileID ──
