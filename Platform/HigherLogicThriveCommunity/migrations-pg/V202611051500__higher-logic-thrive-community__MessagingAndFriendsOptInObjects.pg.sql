-- Higher Logic Thrive Community: four opt-in Private Messaging & Social Graph objects
-- (InboxMessages, SentMessages, Friends, FriendRequests) — PostgreSQL dialect.
--
-- Delta migration: INSERTs are guarded (skip when the ID or (IntegrationID, Name)
-- already exists), so re-running is a no-op. IDs match metadata primaryKey.ID exactly.

DO $mig$
DECLARE
  v_int uuid;
  v_contacts uuid;
BEGIN
  SELECT "ID" INTO v_int FROM __mj."Integration" WHERE "Name" = 'higherlogic-thrive';
  IF v_int IS NULL THEN RAISE NOTICE 'higherlogic-thrive integration not installed - nothing to do'; RETURN; END IF;
  SELECT "ID" INTO v_contacts FROM __mj."IntegrationObject" WHERE "IntegrationID" = v_int AND "Name" = 'Contacts';

  -- ── 1. InboxMessages ────────────────────────────────────────────────────────
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObject" WHERE "ID" = '8B3E41A0-92C4-4D5A-B101-000000000001' OR ("IntegrationID" = v_int AND "Name" = 'InboxMessages')) THEN
    INSERT INTO __mj."IntegrationObject"
        ("ID", "IntegrationID", "Name", "DisplayName", "Description", "Category", "APIPath", "ResponseDataKey",
         "DefaultPageSize", "SupportsPagination", "PaginationType", "SupportsIncrementalSync", "SupportsWrite",
         "Configuration", "Sequence", "Status", "CreateAPIPath", "CreateMethod", "CreateBodyShape", "CreateIDLocation",
         "DeleteAPIPath", "DeleteMethod", "DeleteIDLocation", "SyncStrategy", "ContentHashApplicable", "StableOrderingKey",
         "SupportsCreate", "SupportsUpdate", "SupportsDelete", "MetadataSource")
    VALUES
        ('8B3E41A0-92C4-4D5A-B101-000000000001', v_int, 'InboxMessages', 'Inbox Messages',
         'Private direct messages received in the authenticated member or impersonated contact inbox (GET /v2.0/Messaging/GetInboxMessages). Opt-in via Configuration.includePrivateSocialObjects=true. Supports firstRecord/maxRecords query-offset pagination, SendMessage create, and DeleteInboxMessage delete.',
         'Messaging', '/v2.0/Messaging/GetInboxMessages', NULL, 50, true, 'Offset', false, true,
         '{"optInGroup": "PrivateSocialObjects", "optInConfigKey": "includePrivateSocialObjects", "accessPath": {"door": "Messaging/GetInboxMessages", "path": "/v2.0/Messaging/GetInboxMessages", "readMethod": "GET", "nesting": [], "door_args": ["firstRecord", "maxRecords"]}, "paginationDetail": {"type": "Offset", "subtype": "query-offset", "params": ["firstRecord", "maxRecords"]}, "sourceModel": "PrivateMessage"}',
         36, 'Active', '/v2.0/Messaging/SendMessage', 'POST', 'flat', 'body',
         '/v2.0/Messaging/DeleteInboxMessage?messageKey={id}', 'DELETE', 'path',
         'FullPullHashDiff', true, 'MessageKey', true, false, true, 'Declared');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B101-100000000001' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B101-000000000001' AND "Name" = 'MessageKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B101-100000000001', '8B3E41A0-92C4-4D5A-B101-000000000001', 'MessageKey', 'Message Key', 'Unique GUID identifier for the private message.', 'String', NULL,
         true, true, true, true, false, NULL, NULL, 1, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B101-100000000002' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B101-000000000001' AND "Name" = 'SenderContactKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B101-100000000002', '8B3E41A0-92C4-4D5A-B101-000000000001', 'SenderContactKey', 'Sender Contact Key', 'ContactKey of the member who sent the private message.', 'String', NULL,
         false, false, false, false, true, v_contacts, 'ContactKey', 2, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B101-100000000003' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B101-000000000001' AND "Name" = 'RecipientContactKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B101-100000000003', '8B3E41A0-92C4-4D5A-B101-000000000001', 'RecipientContactKey', 'Recipient Contact Key', 'ContactKey of the member receiving the private message.', 'String', NULL,
         false, false, false, false, true, v_contacts, 'ContactKey', 3, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B101-100000000004' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B101-000000000001' AND "Name" = 'Subject')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B101-100000000004', '8B3E41A0-92C4-4D5A-B101-000000000001', 'Subject', 'Subject', 'Subject line of the private message.', 'String', NULL,
         false, false, false, false, true, NULL, NULL, 4, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B101-100000000005' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B101-000000000001' AND "Name" = 'Body')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B101-100000000005', '8B3E41A0-92C4-4D5A-B101-000000000001', 'Body', 'Body', 'Message body content.', 'String', 4000,
         false, false, false, false, true, NULL, NULL, 5, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B101-100000000006' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B101-000000000001' AND "Name" = 'DateSent')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B101-100000000006', '8B3E41A0-92C4-4D5A-B101-000000000001', 'DateSent', 'Date Sent', 'Timestamp when the message was sent.', 'Datetime', NULL,
         false, true, false, false, true, NULL, NULL, 6, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B101-100000000007' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B101-000000000001' AND "Name" = 'IsRead')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B101-100000000007', '8B3E41A0-92C4-4D5A-B101-000000000001', 'IsRead', 'Is Read', 'Whether the inbox message has been read.', 'Boolean', NULL,
         false, false, false, false, true, NULL, NULL, 7, 'Active');
  END IF;

  -- ── 2. SentMessages ─────────────────────────────────────────────────────────
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObject" WHERE "ID" = '8B3E41A0-92C4-4D5A-B102-000000000002' OR ("IntegrationID" = v_int AND "Name" = 'SentMessages')) THEN
    INSERT INTO __mj."IntegrationObject"
        ("ID", "IntegrationID", "Name", "DisplayName", "Description", "Category", "APIPath", "ResponseDataKey",
         "DefaultPageSize", "SupportsPagination", "PaginationType", "SupportsIncrementalSync", "SupportsWrite",
         "Configuration", "Sequence", "Status", "SyncStrategy", "ContentHashApplicable", "StableOrderingKey",
         "SupportsCreate", "SupportsUpdate", "SupportsDelete", "MetadataSource")
    VALUES
        ('8B3E41A0-92C4-4D5A-B102-000000000002', v_int, 'SentMessages', 'Sent Messages',
         'Private direct messages sent by the authenticated member or impersonated contact (GET /v2.0/Messaging/GetSentMessages). Opt-in via Configuration.includePrivateSocialObjects=true. Uses firstRecord/maxRecords query-offset pagination.',
         'Messaging', '/v2.0/Messaging/GetSentMessages', NULL, 50, true, 'Offset', false, false,
         '{"optInGroup": "PrivateSocialObjects", "optInConfigKey": "includePrivateSocialObjects", "accessPath": {"door": "Messaging/GetSentMessages", "path": "/v2.0/Messaging/GetSentMessages", "readMethod": "GET", "nesting": [], "door_args": ["firstRecord", "maxRecords"]}, "paginationDetail": {"type": "Offset", "subtype": "query-offset", "params": ["firstRecord", "maxRecords"]}, "sourceModel": "PrivateMessage"}',
         37, 'Active', 'FullPullHashDiff', true, 'MessageKey', false, false, false, 'Declared');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B102-200000000001' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B102-000000000002' AND "Name" = 'MessageKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B102-200000000001', '8B3E41A0-92C4-4D5A-B102-000000000002', 'MessageKey', 'Message Key', 'Unique GUID identifier for the sent message.', 'String', NULL,
         true, true, true, true, false, NULL, NULL, 1, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B102-200000000002' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B102-000000000002' AND "Name" = 'SenderContactKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B102-200000000002', '8B3E41A0-92C4-4D5A-B102-000000000002', 'SenderContactKey', 'Sender Contact Key', 'ContactKey of the member who sent the private message.', 'String', NULL,
         false, true, false, false, true, v_contacts, 'ContactKey', 2, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B102-200000000003' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B102-000000000002' AND "Name" = 'RecipientContactKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B102-200000000003', '8B3E41A0-92C4-4D5A-B102-000000000002', 'RecipientContactKey', 'Recipient Contact Key', 'ContactKey of the member who received the private message.', 'String', NULL,
         false, true, false, false, true, v_contacts, 'ContactKey', 3, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B102-200000000004' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B102-000000000002' AND "Name" = 'Subject')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B102-200000000004', '8B3E41A0-92C4-4D5A-B102-000000000002', 'Subject', 'Subject', 'Subject line of the sent message.', 'String', NULL,
         false, true, false, false, true, NULL, NULL, 4, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B102-200000000005' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B102-000000000002' AND "Name" = 'Body')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B102-200000000005', '8B3E41A0-92C4-4D5A-B102-000000000002', 'Body', 'Body', 'Message body content.', 'String', 4000,
         false, true, false, false, true, NULL, NULL, 5, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B102-200000000006' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B102-000000000002' AND "Name" = 'DateSent')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B102-200000000006', '8B3E41A0-92C4-4D5A-B102-000000000002', 'DateSent', 'Date Sent', 'Timestamp when the message was sent.', 'Datetime', NULL,
         false, true, false, false, true, NULL, NULL, 6, 'Active');
  END IF;

  -- ── 3. Friends ──────────────────────────────────────────────────────────────
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObject" WHERE "ID" = '8B3E41A0-92C4-4D5A-B103-000000000003' OR ("IntegrationID" = v_int AND "Name" = 'Friends')) THEN
    INSERT INTO __mj."IntegrationObject"
        ("ID", "IntegrationID", "Name", "DisplayName", "Description", "Category", "APIPath", "ResponseDataKey",
         "SupportsPagination", "PaginationType", "SupportsIncrementalSync", "SupportsWrite",
         "Configuration", "Sequence", "Status", "DeleteAPIPath", "DeleteMethod", "DeleteIDLocation",
         "SyncStrategy", "ContentHashApplicable", "StableOrderingKey",
         "SupportsCreate", "SupportsUpdate", "SupportsDelete", "MetadataSource")
    VALUES
        ('8B3E41A0-92C4-4D5A-B103-000000000003', v_int, 'Friends', 'Friends',
         'Accepted member-to-member friend connections (GET /v2.0/Friends/GetMyFriends). Opt-in via Configuration.includePrivateSocialObjects=true. Supports RemoveFriend delete.',
         'Friends', '/v2.0/Friends/GetMyFriends', NULL, false, 'None', false, true,
         '{"optInGroup": "PrivateSocialObjects", "optInConfigKey": "includePrivateSocialObjects", "accessPath": {"door": "Friends/GetMyFriends", "path": "/v2.0/Friends/GetMyFriends", "readMethod": "GET", "nesting": [], "door_args": []}, "paginationDetail": null, "sourceModel": "ContactConcise"}',
         38, 'Active', '/v2.0/Friends/RemoveFriend?friendContactKey={id}', 'DELETE', 'path',
         'FullPullHashDiff', true, 'ContactKey', false, false, true, 'Declared');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B103-300000000001' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B103-000000000003' AND "Name" = 'ContactKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B103-300000000001', '8B3E41A0-92C4-4D5A-B103-000000000003', 'ContactKey', 'Contact Key', 'ContactKey of the connected friend.', 'String', NULL,
         true, true, true, true, false, v_contacts, 'ContactKey', 1, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B103-300000000002' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B103-000000000003' AND "Name" = 'FirstName')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B103-300000000002', '8B3E41A0-92C4-4D5A-B103-000000000003', 'FirstName', 'First Name', 'Friend''s first name.', 'String', NULL,
         false, true, false, false, true, NULL, NULL, 2, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B103-300000000003' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B103-000000000003' AND "Name" = 'LastName')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B103-300000000003', '8B3E41A0-92C4-4D5A-B103-000000000003', 'LastName', 'Last Name', 'Friend''s last name.', 'String', NULL,
         false, true, false, false, true, NULL, NULL, 3, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B103-300000000004' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B103-000000000003' AND "Name" = 'EmailAddress')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B103-300000000004', '8B3E41A0-92C4-4D5A-B103-000000000003', 'EmailAddress', 'Email Address', 'Friend''s email address.', 'String', 320,
         false, true, false, false, true, NULL, NULL, 4, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B103-300000000005' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B103-000000000003' AND "Name" = 'LegacyContactKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B103-300000000005', '8B3E41A0-92C4-4D5A-B103-000000000003', 'LegacyContactKey', 'Legacy Contact Key', 'AMS/CRM legacy identifier for the connected friend.', 'String', NULL,
         false, true, false, false, true, NULL, NULL, 5, 'Active');
  END IF;

  -- ── 4. FriendRequests ───────────────────────────────────────────────────────
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObject" WHERE "ID" = '8B3E41A0-92C4-4D5A-B104-000000000004' OR ("IntegrationID" = v_int AND "Name" = 'FriendRequests')) THEN
    INSERT INTO __mj."IntegrationObject"
        ("ID", "IntegrationID", "Name", "DisplayName", "Description", "Category", "APIPath", "ResponseDataKey",
         "SupportsPagination", "PaginationType", "SupportsIncrementalSync", "SupportsWrite",
         "Configuration", "Sequence", "Status", "CreateAPIPath", "CreateMethod", "CreateBodyShape", "CreateIDLocation",
         "SyncStrategy", "ContentHashApplicable", "StableOrderingKey",
         "SupportsCreate", "SupportsUpdate", "SupportsDelete", "MetadataSource")
    VALUES
        ('8B3E41A0-92C4-4D5A-B104-000000000004', v_int, 'FriendRequests', 'Friend Requests',
         'Pending member-to-member friend invitations (GET /v2.0/Friends/GetFriendRequestsReceived, plus optional GetFriendRequestsSent merge when includeSent=true). Opt-in via Configuration.includePrivateSocialObjects=true. Supports RequestFriend create.',
         'Friends', '/v2.0/Friends/GetFriendRequestsReceived', NULL, false, 'None', false, true,
         '{"optInGroup": "PrivateSocialObjects", "optInConfigKey": "includePrivateSocialObjects", "secondaryAPIPath": "/v2.0/Friends/GetFriendRequestsSent", "accessPath": {"door": "Friends/GetFriendRequestsReceived", "path": "/v2.0/Friends/GetFriendRequestsReceived", "readMethod": "GET", "nesting": [], "door_args": []}, "paginationDetail": null, "sourceModel": "FriendRequest"}',
         39, 'Active', '/v2.0/Friends/RequestFriend?friendContactKey={friendContactKey}', 'POST', 'flat', 'n/a',
         'FullPullHashDiff', true, 'FriendRequestKey', true, false, false, 'Declared');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B104-400000000001' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B104-000000000004' AND "Name" = 'FriendRequestKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B104-400000000001', '8B3E41A0-92C4-4D5A-B104-000000000004', 'FriendRequestKey', 'Friend Request Key', 'Unique GUID identifier for the friend request.', 'String', NULL,
         true, true, true, true, false, NULL, NULL, 1, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B104-400000000002' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B104-000000000004' AND "Name" = 'RequesterContactKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B104-400000000002', '8B3E41A0-92C4-4D5A-B104-000000000004', 'RequesterContactKey', 'Requester Contact Key', 'ContactKey of the member who initiated the friend request.', 'String', NULL,
         false, false, false, false, true, v_contacts, 'ContactKey', 2, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B104-400000000003' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B104-000000000004' AND "Name" = 'RecipientContactKey')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B104-400000000003', '8B3E41A0-92C4-4D5A-B104-000000000004', 'RecipientContactKey', 'Recipient Contact Key', 'ContactKey of the member who received the friend request.', 'String', NULL,
         false, false, false, false, true, v_contacts, 'ContactKey', 3, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B104-400000000004' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B104-000000000004' AND "Name" = 'Direction')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B104-400000000004', '8B3E41A0-92C4-4D5A-B104-000000000004', 'Direction', 'Direction', 'Request direction relative to the authenticated member (''Received'' or ''Sent'').', 'String', NULL,
         false, true, false, false, true, NULL, NULL, 4, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B104-400000000005' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B104-000000000004' AND "Name" = 'Status')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B104-400000000005', '8B3E41A0-92C4-4D5A-B104-000000000004', 'Status', 'Status', 'Current status of the friend invitation.', 'String', NULL,
         false, true, false, false, true, NULL, NULL, 5, 'Active');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM __mj."IntegrationObjectField" WHERE "ID" = '8B3E41A0-92C4-4D5A-B104-400000000006' OR ("IntegrationObjectID" = '8B3E41A0-92C4-4D5A-B104-000000000004' AND "Name" = 'CreatedOn')) THEN
    INSERT INTO __mj."IntegrationObjectField"
        ("ID", "IntegrationObjectID", "Name", "DisplayName", "Description", "Type", "Length",
         "IsRequired", "IsReadOnly", "IsPrimaryKey", "IsUniqueKey", "AllowsNull",
         "RelatedIntegrationObjectID", "RelatedIntegrationObjectFieldName", "Sequence", "Status")
    VALUES
        ('8B3E41A0-92C4-4D5A-B104-400000000006', '8B3E41A0-92C4-4D5A-B104-000000000004', 'CreatedOn', 'Created On', 'Timestamp when the friend request was created.', 'Datetime', NULL,
         false, true, false, false, true, NULL, NULL, 6, 'Active');
  END IF;
END $mig$;
