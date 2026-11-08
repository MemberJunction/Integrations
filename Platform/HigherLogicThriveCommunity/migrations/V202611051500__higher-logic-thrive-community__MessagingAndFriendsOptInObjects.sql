-- Higher Logic Thrive Community: four opt-in Private Messaging & Social Graph objects
-- (InboxMessages, SentMessages, Friends, FriendRequests).
--
-- Opt-in via CompanyIntegration.Configuration.includePrivateSocialObjects = true so routine
-- public-community analytics syncs skip private member DMs and friend graphs while full
-- community migrations can bring them over with query-offset (firstRecord/maxRecords) pagination.
--
-- Object creation uses the guarded spCreateIntegrationObject form (the shape the
-- catalog-completeness gate resolves objects from); fields ship as guarded INSERTs,
-- which the gate counts by their hardcoded ID literals. Re-running is a no-op:
-- every create is guarded on both the hardcoded ID and (IntegrationID, Name).
-- IDs match metadata primaryKey.ID exactly.

DECLARE @IntID UNIQUEIDENTIFIER = (SELECT ID FROM [__mj].Integration WHERE Name = 'higherlogic-thrive');
DECLARE @ContactsObjID UNIQUEIDENTIFIER = (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = N'Contacts');

-- ── 1. InboxMessages ────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = '8B3E41A0-92C4-4D5A-B101-000000000001' OR (IntegrationID = @IntID AND Name = N'InboxMessages'))
BEGIN
    DECLARE @ID_8b3e41a1 UNIQUEIDENTIFIER, @Name_8b3e41a1 NVARCHAR(255), @DisplayName_8b3e41a1 NVARCHAR(255),
            @Description_8b3e41a1 NVARCHAR(MAX), @Category_8b3e41a1 NVARCHAR(100), @APIPath_8b3e41a1 NVARCHAR(500),
            @Configuration_8b3e41a1 NVARCHAR(MAX)
    SET @ID_8b3e41a1 = '8B3E41A0-92C4-4D5A-B101-000000000001'
    SET @Name_8b3e41a1 = N'InboxMessages'
    SET @DisplayName_8b3e41a1 = N'Inbox Messages'
    SET @Description_8b3e41a1 = N'Private direct messages received in the authenticated member or impersonated contact inbox (GET /v2.0/Messaging/GetInboxMessages). Opt-in via Configuration.includePrivateSocialObjects=true. Supports firstRecord/maxRecords query-offset pagination, SendMessage create, and DeleteInboxMessage delete.'
    SET @Category_8b3e41a1 = N'Messaging'
    SET @APIPath_8b3e41a1 = N'/v2.0/Messaging/GetInboxMessages'
    SET @Configuration_8b3e41a1 = N'{"optInGroup": "PrivateSocialObjects", "optInConfigKey": "includePrivateSocialObjects", "accessPath": {"door": "Messaging/GetInboxMessages", "path": "/v2.0/Messaging/GetInboxMessages", "readMethod": "GET", "nesting": [], "door_args": ["firstRecord", "maxRecords"]}, "paginationDetail": {"type": "Offset", "subtype": "query-offset", "params": ["firstRecord", "maxRecords"]}, "sourceModel": "PrivateMessage"}'
    EXEC [__mj].spCreateIntegrationObject @ID = @ID_8b3e41a1,
      @IntegrationID = @IntID,
      @Name = @Name_8b3e41a1,
      @DisplayName = @DisplayName_8b3e41a1,
      @Description = @Description_8b3e41a1,
      @Category = @Category_8b3e41a1,
      @APIPath = @APIPath_8b3e41a1,
      @ResponseDataKey = NULL,
      @DefaultPageSize = 50,
      @SupportsPagination = 1,
      @PaginationType = N'Offset',
      @SupportsIncrementalSync = 0,
      @SupportsWrite = 1,
      @DefaultQueryParams = NULL,
      @Configuration = @Configuration_8b3e41a1,
      @Sequence = 36,
      @Status = N'Active',
      @CreateAPIPath = N'/v2.0/Messaging/SendMessage',
      @CreateMethod = N'POST',
      @CreateBodyShape = N'flat',
      @CreateIDLocation = N'body',
      @DeleteAPIPath = N'/v2.0/Messaging/DeleteInboxMessage?messageKey={id}',
      @DeleteMethod = N'DELETE',
      @DeleteIDLocation = N'path',
      @SyncStrategy = N'FullPullHashDiff',
      @ContentHashApplicable = 1,
      @StableOrderingKey = N'MessageKey',
      @SupportsCreate = 1,
      @SupportsUpdate = 0,
      @SupportsDelete = 1,
      @MetadataSource = N'Declared'
END
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B101-100000000001' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B101-000000000001' AND Name = N'MessageKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B101-100000000001', '8B3E41A0-92C4-4D5A-B101-000000000001', N'MessageKey', N'Message Key', N'Unique GUID identifier for the private message.', N'String', NULL,
     1, 1, 1, 1, 0, NULL, NULL, 1, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B101-100000000002' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B101-000000000001' AND Name = N'SenderContactKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B101-100000000002', '8B3E41A0-92C4-4D5A-B101-000000000001', N'SenderContactKey', N'Sender Contact Key', N'ContactKey of the member who sent the private message.', N'String', NULL,
     0, 0, 0, 0, 1, @ContactsObjID, N'ContactKey', 2, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B101-100000000003' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B101-000000000001' AND Name = N'RecipientContactKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B101-100000000003', '8B3E41A0-92C4-4D5A-B101-000000000001', N'RecipientContactKey', N'Recipient Contact Key', N'ContactKey of the member receiving the private message.', N'String', NULL,
     0, 0, 0, 0, 1, @ContactsObjID, N'ContactKey', 3, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B101-100000000004' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B101-000000000001' AND Name = N'Subject'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B101-100000000004', '8B3E41A0-92C4-4D5A-B101-000000000001', N'Subject', N'Subject', N'Subject line of the private message.', N'String', NULL,
     0, 0, 0, 0, 1, NULL, NULL, 4, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B101-100000000005' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B101-000000000001' AND Name = N'Body'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B101-100000000005', '8B3E41A0-92C4-4D5A-B101-000000000001', N'Body', N'Body', N'Message body content.', N'String', 4000,
     0, 0, 0, 0, 1, NULL, NULL, 5, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B101-100000000006' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B101-000000000001' AND Name = N'DateSent'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B101-100000000006', '8B3E41A0-92C4-4D5A-B101-000000000001', N'DateSent', N'Date Sent', N'Timestamp when the message was sent.', N'Datetime', NULL,
     0, 1, 0, 0, 1, NULL, NULL, 6, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B101-100000000007' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B101-000000000001' AND Name = N'IsRead'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B101-100000000007', '8B3E41A0-92C4-4D5A-B101-000000000001', N'IsRead', N'Is Read', N'Whether the inbox message has been read.', N'Boolean', NULL,
     0, 0, 0, 0, 1, NULL, NULL, 7, N'Active');

-- ── 2. SentMessages ─────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = '8B3E41A0-92C4-4D5A-B102-000000000002' OR (IntegrationID = @IntID AND Name = N'SentMessages'))
BEGIN
    DECLARE @ID_8b3e41a2 UNIQUEIDENTIFIER, @Name_8b3e41a2 NVARCHAR(255), @DisplayName_8b3e41a2 NVARCHAR(255),
            @Description_8b3e41a2 NVARCHAR(MAX), @Category_8b3e41a2 NVARCHAR(100), @APIPath_8b3e41a2 NVARCHAR(500),
            @Configuration_8b3e41a2 NVARCHAR(MAX)
    SET @ID_8b3e41a2 = '8B3E41A0-92C4-4D5A-B102-000000000002'
    SET @Name_8b3e41a2 = N'SentMessages'
    SET @DisplayName_8b3e41a2 = N'Sent Messages'
    SET @Description_8b3e41a2 = N'Private direct messages sent by the authenticated member or impersonated contact (GET /v2.0/Messaging/GetSentMessages). Opt-in via Configuration.includePrivateSocialObjects=true. Uses firstRecord/maxRecords query-offset pagination.'
    SET @Category_8b3e41a2 = N'Messaging'
    SET @APIPath_8b3e41a2 = N'/v2.0/Messaging/GetSentMessages'
    SET @Configuration_8b3e41a2 = N'{"optInGroup": "PrivateSocialObjects", "optInConfigKey": "includePrivateSocialObjects", "accessPath": {"door": "Messaging/GetSentMessages", "path": "/v2.0/Messaging/GetSentMessages", "readMethod": "GET", "nesting": [], "door_args": ["firstRecord", "maxRecords"]}, "paginationDetail": {"type": "Offset", "subtype": "query-offset", "params": ["firstRecord", "maxRecords"]}, "sourceModel": "PrivateMessage"}'
    EXEC [__mj].spCreateIntegrationObject @ID = @ID_8b3e41a2,
      @IntegrationID = @IntID,
      @Name = @Name_8b3e41a2,
      @DisplayName = @DisplayName_8b3e41a2,
      @Description = @Description_8b3e41a2,
      @Category = @Category_8b3e41a2,
      @APIPath = @APIPath_8b3e41a2,
      @ResponseDataKey = NULL,
      @DefaultPageSize = 50,
      @SupportsPagination = 1,
      @PaginationType = N'Offset',
      @SupportsIncrementalSync = 0,
      @SupportsWrite = 0,
      @DefaultQueryParams = NULL,
      @Configuration = @Configuration_8b3e41a2,
      @Sequence = 37,
      @Status = N'Active',
      @SyncStrategy = N'FullPullHashDiff',
      @ContentHashApplicable = 1,
      @StableOrderingKey = N'MessageKey',
      @SupportsCreate = 0,
      @SupportsUpdate = 0,
      @SupportsDelete = 0,
      @MetadataSource = N'Declared'
END
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B102-200000000001' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B102-000000000002' AND Name = N'MessageKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B102-200000000001', '8B3E41A0-92C4-4D5A-B102-000000000002', N'MessageKey', N'Message Key', N'Unique GUID identifier for the sent message.', N'String', NULL,
     1, 1, 1, 1, 0, NULL, NULL, 1, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B102-200000000002' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B102-000000000002' AND Name = N'SenderContactKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B102-200000000002', '8B3E41A0-92C4-4D5A-B102-000000000002', N'SenderContactKey', N'Sender Contact Key', N'ContactKey of the member who sent the private message.', N'String', NULL,
     0, 1, 0, 0, 1, @ContactsObjID, N'ContactKey', 2, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B102-200000000003' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B102-000000000002' AND Name = N'RecipientContactKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B102-200000000003', '8B3E41A0-92C4-4D5A-B102-000000000002', N'RecipientContactKey', N'Recipient Contact Key', N'ContactKey of the member who received the private message.', N'String', NULL,
     0, 1, 0, 0, 1, @ContactsObjID, N'ContactKey', 3, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B102-200000000004' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B102-000000000002' AND Name = N'Subject'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B102-200000000004', '8B3E41A0-92C4-4D5A-B102-000000000002', N'Subject', N'Subject', N'Subject line of the sent message.', N'String', NULL,
     0, 1, 0, 0, 1, NULL, NULL, 4, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B102-200000000005' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B102-000000000002' AND Name = N'Body'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B102-200000000005', '8B3E41A0-92C4-4D5A-B102-000000000002', N'Body', N'Body', N'Message body content.', N'String', 4000,
     0, 1, 0, 0, 1, NULL, NULL, 5, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B102-200000000006' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B102-000000000002' AND Name = N'DateSent'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B102-200000000006', '8B3E41A0-92C4-4D5A-B102-000000000002', N'DateSent', N'Date Sent', N'Timestamp when the message was sent.', N'Datetime', NULL,
     0, 1, 0, 0, 1, NULL, NULL, 6, N'Active');

-- ── 3. Friends ──────────────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = '8B3E41A0-92C4-4D5A-B103-000000000003' OR (IntegrationID = @IntID AND Name = N'Friends'))
BEGIN
    DECLARE @ID_8b3e41a3 UNIQUEIDENTIFIER, @Name_8b3e41a3 NVARCHAR(255), @DisplayName_8b3e41a3 NVARCHAR(255),
            @Description_8b3e41a3 NVARCHAR(MAX), @Category_8b3e41a3 NVARCHAR(100), @APIPath_8b3e41a3 NVARCHAR(500),
            @Configuration_8b3e41a3 NVARCHAR(MAX)
    SET @ID_8b3e41a3 = '8B3E41A0-92C4-4D5A-B103-000000000003'
    SET @Name_8b3e41a3 = N'Friends'
    SET @DisplayName_8b3e41a3 = N'Friends'
    SET @Description_8b3e41a3 = N'Accepted member-to-member friend connections (GET /v2.0/Friends/GetMyFriends). Opt-in via Configuration.includePrivateSocialObjects=true. Supports RemoveFriend delete.'
    SET @Category_8b3e41a3 = N'Friends'
    SET @APIPath_8b3e41a3 = N'/v2.0/Friends/GetMyFriends'
    SET @Configuration_8b3e41a3 = N'{"optInGroup": "PrivateSocialObjects", "optInConfigKey": "includePrivateSocialObjects", "accessPath": {"door": "Friends/GetMyFriends", "path": "/v2.0/Friends/GetMyFriends", "readMethod": "GET", "nesting": [], "door_args": []}, "paginationDetail": null, "sourceModel": "ContactConcise"}'
    EXEC [__mj].spCreateIntegrationObject @ID = @ID_8b3e41a3,
      @IntegrationID = @IntID,
      @Name = @Name_8b3e41a3,
      @DisplayName = @DisplayName_8b3e41a3,
      @Description = @Description_8b3e41a3,
      @Category = @Category_8b3e41a3,
      @APIPath = @APIPath_8b3e41a3,
      @ResponseDataKey = NULL,
      @DefaultPageSize = 0,
      @SupportsPagination = 0,
      @PaginationType = N'None',
      @SupportsIncrementalSync = 0,
      @SupportsWrite = 1,
      @DefaultQueryParams = NULL,
      @Configuration = @Configuration_8b3e41a3,
      @Sequence = 38,
      @Status = N'Active',
      @DeleteAPIPath = N'/v2.0/Friends/RemoveFriend?friendContactKey={id}',
      @DeleteMethod = N'DELETE',
      @DeleteIDLocation = N'path',
      @SyncStrategy = N'FullPullHashDiff',
      @ContentHashApplicable = 1,
      @StableOrderingKey = N'ContactKey',
      @SupportsCreate = 0,
      @SupportsUpdate = 0,
      @SupportsDelete = 1,
      @MetadataSource = N'Declared'
END
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B103-300000000001' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B103-000000000003' AND Name = N'ContactKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B103-300000000001', '8B3E41A0-92C4-4D5A-B103-000000000003', N'ContactKey', N'Contact Key', N'ContactKey of the connected friend.', N'String', NULL,
     1, 1, 1, 1, 0, @ContactsObjID, N'ContactKey', 1, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B103-300000000002' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B103-000000000003' AND Name = N'FirstName'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B103-300000000002', '8B3E41A0-92C4-4D5A-B103-000000000003', N'FirstName', N'First Name', N'Friend''s first name.', N'String', NULL,
     0, 1, 0, 0, 1, NULL, NULL, 2, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B103-300000000003' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B103-000000000003' AND Name = N'LastName'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B103-300000000003', '8B3E41A0-92C4-4D5A-B103-000000000003', N'LastName', N'Last Name', N'Friend''s last name.', N'String', NULL,
     0, 1, 0, 0, 1, NULL, NULL, 3, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B103-300000000004' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B103-000000000003' AND Name = N'EmailAddress'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B103-300000000004', '8B3E41A0-92C4-4D5A-B103-000000000003', N'EmailAddress', N'Email Address', N'Friend''s email address.', N'String', 320,
     0, 1, 0, 0, 1, NULL, NULL, 4, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B103-300000000005' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B103-000000000003' AND Name = N'LegacyContactKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B103-300000000005', '8B3E41A0-92C4-4D5A-B103-000000000003', N'LegacyContactKey', N'Legacy Contact Key', N'AMS/CRM legacy identifier for the connected friend.', N'String', NULL,
     0, 1, 0, 0, 1, NULL, NULL, 5, N'Active');

-- ── 4. FriendRequests ───────────────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = '8B3E41A0-92C4-4D5A-B104-000000000004' OR (IntegrationID = @IntID AND Name = N'FriendRequests'))
BEGIN
    DECLARE @ID_8b3e41a4 UNIQUEIDENTIFIER, @Name_8b3e41a4 NVARCHAR(255), @DisplayName_8b3e41a4 NVARCHAR(255),
            @Description_8b3e41a4 NVARCHAR(MAX), @Category_8b3e41a4 NVARCHAR(100), @APIPath_8b3e41a4 NVARCHAR(500),
            @Configuration_8b3e41a4 NVARCHAR(MAX)
    SET @ID_8b3e41a4 = '8B3E41A0-92C4-4D5A-B104-000000000004'
    SET @Name_8b3e41a4 = N'FriendRequests'
    SET @DisplayName_8b3e41a4 = N'Friend Requests'
    SET @Description_8b3e41a4 = N'Pending member-to-member friend invitations (GET /v2.0/Friends/GetFriendRequestsReceived, plus optional GetFriendRequestsSent merge when includeSent=true). Opt-in via Configuration.includePrivateSocialObjects=true. Supports RequestFriend create.'
    SET @Category_8b3e41a4 = N'Friends'
    SET @APIPath_8b3e41a4 = N'/v2.0/Friends/GetFriendRequestsReceived'
    SET @Configuration_8b3e41a4 = N'{"optInGroup": "PrivateSocialObjects", "optInConfigKey": "includePrivateSocialObjects", "secondaryAPIPath": "/v2.0/Friends/GetFriendRequestsSent", "accessPath": {"door": "Friends/GetFriendRequestsReceived", "path": "/v2.0/Friends/GetFriendRequestsReceived", "readMethod": "GET", "nesting": [], "door_args": []}, "paginationDetail": null, "sourceModel": "FriendRequest"}'
    EXEC [__mj].spCreateIntegrationObject @ID = @ID_8b3e41a4,
      @IntegrationID = @IntID,
      @Name = @Name_8b3e41a4,
      @DisplayName = @DisplayName_8b3e41a4,
      @Description = @Description_8b3e41a4,
      @Category = @Category_8b3e41a4,
      @APIPath = @APIPath_8b3e41a4,
      @ResponseDataKey = NULL,
      @DefaultPageSize = 0,
      @SupportsPagination = 0,
      @PaginationType = N'None',
      @SupportsIncrementalSync = 0,
      @SupportsWrite = 1,
      @DefaultQueryParams = NULL,
      @Configuration = @Configuration_8b3e41a4,
      @Sequence = 39,
      @Status = N'Active',
      @CreateAPIPath = N'/v2.0/Friends/RequestFriend?friendContactKey={friendContactKey}',
      @CreateMethod = N'POST',
      @CreateBodyShape = N'flat',
      @CreateIDLocation = N'n/a',
      @SyncStrategy = N'FullPullHashDiff',
      @ContentHashApplicable = 1,
      @StableOrderingKey = N'FriendRequestKey',
      @SupportsCreate = 1,
      @SupportsUpdate = 0,
      @SupportsDelete = 0,
      @MetadataSource = N'Declared'
END
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B104-400000000001' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B104-000000000004' AND Name = N'FriendRequestKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B104-400000000001', '8B3E41A0-92C4-4D5A-B104-000000000004', N'FriendRequestKey', N'Friend Request Key', N'Unique GUID identifier for the friend request.', N'String', NULL,
     1, 1, 1, 1, 0, NULL, NULL, 1, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B104-400000000002' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B104-000000000004' AND Name = N'RequesterContactKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B104-400000000002', '8B3E41A0-92C4-4D5A-B104-000000000004', N'RequesterContactKey', N'Requester Contact Key', N'ContactKey of the member who initiated the friend request.', N'String', NULL,
     0, 0, 0, 0, 1, @ContactsObjID, N'ContactKey', 2, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B104-400000000003' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B104-000000000004' AND Name = N'RecipientContactKey'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B104-400000000003', '8B3E41A0-92C4-4D5A-B104-000000000004', N'RecipientContactKey', N'Recipient Contact Key', N'ContactKey of the member who received the friend request.', N'String', NULL,
     0, 0, 0, 0, 1, @ContactsObjID, N'ContactKey', 3, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B104-400000000004' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B104-000000000004' AND Name = N'Direction'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B104-400000000004', '8B3E41A0-92C4-4D5A-B104-000000000004', N'Direction', N'Direction', N'Request direction relative to the authenticated member (''Received'' or ''Sent'').', N'String', NULL,
     0, 1, 0, 0, 1, NULL, NULL, 4, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B104-400000000005' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B104-000000000004' AND Name = N'Status'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B104-400000000005', '8B3E41A0-92C4-4D5A-B104-000000000004', N'Status', N'Status', N'Current status of the friend invitation.', N'String', NULL,
     0, 1, 0, 0, 1, NULL, NULL, 5, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '8B3E41A0-92C4-4D5A-B104-400000000006' OR (IntegrationObjectID = '8B3E41A0-92C4-4D5A-B104-000000000004' AND Name = N'CreatedOn'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('8B3E41A0-92C4-4D5A-B104-400000000006', '8B3E41A0-92C4-4D5A-B104-000000000004', N'CreatedOn', N'Created On', N'Timestamp when the friend request was created.', N'Datetime', NULL,
     0, 1, 0, 0, 1, NULL, NULL, 6, N'Active');
