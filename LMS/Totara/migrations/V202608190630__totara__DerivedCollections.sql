-- Totara: five derived child objects — the embedded JSON arrays become first-class tables.
--
-- Profiled live (2026-08-19): Enrolled_Users.roles / .groups, Users.customfields,
-- Course_Contents.modules and Cohort_Members.userids each landed as one NVARCHAR(MAX)
-- column of JSON text — present, but unqueryable. Each becomes a derived object whose
-- fetch is served from the PARENT object's own walk, as the data comes in (see
-- Configuration.derivedCollection and src/DerivedCollections.ts). No engine change.
--
-- Also declares Configuration.dropFields on Users / Enrolled Users / Courses:
-- preferences (Moodle UI widget state — the same nine keys on 100% of rows) and
-- courseformatoptions (course theming) are configuration, not data, and stop being
-- fetched. Existing columns are untouched and simply stop being written.
--
-- Object creation uses the guarded spCreateIntegrationObject form (the shape the
-- catalog-completeness gate resolves objects from); fields ship as guarded INSERTs,
-- which the gate counts by their hardcoded ID literals. Re-running is a no-op:
-- every create is guarded on both the hardcoded ID and (IntegrationID, Name).
-- IDs match metadata primaryKey.ID exactly — nothing here is hand-minted.

DECLARE @IntID UNIQUEIDENTIFIER = (SELECT ID FROM [__mj].Integration WHERE Name = 'totara');


-- ── Enrolled User Roles ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' OR (IntegrationID = @IntID AND Name = N'Enrolled User Roles'))
BEGIN
    DECLARE @ID_e3f16ebc UNIQUEIDENTIFIER, @Name_e3f16ebc NVARCHAR(255), @DisplayName_e3f16ebc NVARCHAR(255),
            @Description_e3f16ebc NVARCHAR(MAX), @Category_e3f16ebc NVARCHAR(100), @APIPath_e3f16ebc NVARCHAR(500),
            @Configuration_e3f16ebc NVARCHAR(MAX)
    SET @ID_e3f16ebc = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8'
    SET @Name_e3f16ebc = N'Enrolled User Roles'
    SET @DisplayName_e3f16ebc = N'Enrolled User Roles'
    SET @Description_e3f16ebc = N'One row per role a user holds in a course, exploded from Enrolled Users.roles. Previously a JSON array column; profiled live at 0-3 elements per enrolment (avg 1.10).'
    SET @Category_e3f16ebc = N'Users & Cohorts'
    SET @APIPath_e3f16ebc = N'/webservice/rest/server.php'
    SET @Configuration_e3f16ebc = N'{"derivedCollection": {"parentObjectName": "Enrolled Users", "collectionField": "roles", "parentKeyMap": {"id": "userid", "courseid": "courseid"}, "elementKind": "object"}, "syncStrategy": "Derived: rides the parent object''s fetch (same pagination, parent-scoping and budgets; the parent cursor passes through unchanged) and explodes one array field into child records. FullPullHashDiff like the parent.", "derivationNote": "Exploded from Enrolled Users.roles. Measured live 2026-08-19: the array previously landed as one NVARCHAR(MAX) JSON column - present but unqueryable."}'
    EXEC [__mj].spCreateIntegrationObject @ID = @ID_e3f16ebc,
      @IntegrationID = @IntID,
      @Name = @Name_e3f16ebc,
      @DisplayName = @DisplayName_e3f16ebc,
      @Description = @Description_e3f16ebc,
      @Category = @Category_e3f16ebc,
      @APIPath = @APIPath_e3f16ebc,
      @ResponseDataKey = NULL,
      @DefaultPageSize = 0,
      @SupportsPagination = 0,
      @PaginationType = N'None',
      @SupportsIncrementalSync = 0,
      @SupportsWrite = 0,
      @DefaultQueryParams = NULL,
      @Configuration = @Configuration_e3f16ebc,
      @Sequence = 29,
      @Status = N'Active',
      @SupportsCreate = 0,
      @SupportsUpdate = 0,
      @SupportsDelete = 0,
      @MetadataSource = N'Declared'
END
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '464CBE3D-6C4A-4C6C-9662-CCC5D423B39B' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = N'userid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('464CBE3D-6C4A-4C6C-9662-CCC5D423B39B', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', N'userid', N'User ID', N'user id (Enrolled Users.id, renamed to avoid colliding with the element)', N'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = N'Users'), N'id', 1, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'D46C15C8-8700-4019-9EE3-CBC92655F0DC' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = N'courseid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('D46C15C8-8700-4019-9EE3-CBC92655F0DC', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', N'courseid', N'Course ID', N'course the role applies in', N'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = N'Courses'), N'id', 2, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '60F414FE-6F18-4424-A1E6-BB94028C8946' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = N'roleid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('60F414FE-6F18-4424-A1E6-BB94028C8946', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', N'roleid', N'Role ID', N'Totara role id', N'integer', NULL,
     1, 1, 1, 1, 0,
     NULL, NULL, 3, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'F22904FC-6FA4-48A2-89EF-C2F71E4A791A' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = N'shortname'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('F22904FC-6FA4-48A2-89EF-C2F71E4A791A', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', N'shortname', N'Short Name', N'role shortname (e.g. student, editingteacher)', N'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 4, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '68D5A506-ADB0-40E5-9457-BD564C9582F8' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = N'name'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('68D5A506-ADB0-40E5-9457-BD564C9582F8', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', N'name', N'Name', N'role display name', N'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 5, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'ABC9D9A1-07D6-42B1-BDD8-EB3310CEBA2C' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = N'sortorder'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('ABC9D9A1-07D6-42B1-BDD8-EB3310CEBA2C', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', N'sortorder', N'Sort Order', N'role sort order', N'integer', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 6, N'Active');

-- ── Enrolled User Groups ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' OR (IntegrationID = @IntID AND Name = N'Enrolled User Groups'))
BEGIN
    DECLARE @ID_51f83ba6 UNIQUEIDENTIFIER, @Name_51f83ba6 NVARCHAR(255), @DisplayName_51f83ba6 NVARCHAR(255),
            @Description_51f83ba6 NVARCHAR(MAX), @Category_51f83ba6 NVARCHAR(100), @APIPath_51f83ba6 NVARCHAR(500),
            @Configuration_51f83ba6 NVARCHAR(MAX)
    SET @ID_51f83ba6 = '51F83BA6-CCE7-447B-826D-DECE9DC39B26'
    SET @Name_51f83ba6 = N'Enrolled User Groups'
    SET @DisplayName_51f83ba6 = N'Enrolled User Groups'
    SET @Description_51f83ba6 = N'One row per group membership within a course, exploded from Enrolled Users.groups. Element id is the GROUP id and is renamed groupid.'
    SET @Category_51f83ba6 = N'Users & Cohorts'
    SET @APIPath_51f83ba6 = N'/webservice/rest/server.php'
    SET @Configuration_51f83ba6 = N'{"derivedCollection": {"parentObjectName": "Enrolled Users", "collectionField": "groups", "parentKeyMap": {"id": "userid", "courseid": "courseid"}, "elementKind": "object", "elementKeyMap": {"id": "groupid"}}, "syncStrategy": "Derived: rides the parent object''s fetch (same pagination, parent-scoping and budgets; the parent cursor passes through unchanged) and explodes one array field into child records. FullPullHashDiff like the parent.", "derivationNote": "Exploded from Enrolled Users.groups. Measured live 2026-08-19: the array previously landed as one NVARCHAR(MAX) JSON column - present but unqueryable."}'
    EXEC [__mj].spCreateIntegrationObject @ID = @ID_51f83ba6,
      @IntegrationID = @IntID,
      @Name = @Name_51f83ba6,
      @DisplayName = @DisplayName_51f83ba6,
      @Description = @Description_51f83ba6,
      @Category = @Category_51f83ba6,
      @APIPath = @APIPath_51f83ba6,
      @ResponseDataKey = NULL,
      @DefaultPageSize = 0,
      @SupportsPagination = 0,
      @PaginationType = N'None',
      @SupportsIncrementalSync = 0,
      @SupportsWrite = 0,
      @DefaultQueryParams = NULL,
      @Configuration = @Configuration_51f83ba6,
      @Sequence = 30,
      @Status = N'Active',
      @SupportsCreate = 0,
      @SupportsUpdate = 0,
      @SupportsDelete = 0,
      @MetadataSource = N'Declared'
END
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'F9DD45FE-804E-48BB-93DC-A78E3A84DC8E' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = N'userid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('F9DD45FE-804E-48BB-93DC-A78E3A84DC8E', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', N'userid', N'User ID', N'user id (Enrolled Users.id)', N'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = N'Users'), N'id', 1, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '9094721F-A99D-400F-B8B2-57F0CE0AFB01' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = N'courseid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('9094721F-A99D-400F-B8B2-57F0CE0AFB01', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', N'courseid', N'Course ID', N'course the group belongs to', N'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = N'Courses'), N'id', 2, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '85B56C12-D5DA-402E-ACE4-4B994B1D23A8' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = N'groupid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('85B56C12-D5DA-402E-ACE4-4B994B1D23A8', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', N'groupid', N'Group ID', N'group id (element id, renamed)', N'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = N'Groups'), N'id', 3, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'C859B98A-41B3-45BA-AF05-A2A777B0932F' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = N'name'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('C859B98A-41B3-45BA-AF05-A2A777B0932F', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', N'name', N'Name', N'group name', N'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 4, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '2994EE74-D5AE-4E3E-8DE0-61937438FB1E' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = N'description'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('2994EE74-D5AE-4E3E-8DE0-61937438FB1E', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', N'description', N'Description', N'group description', N'string', 4000,
     0, 1, 0, 0, 1,
     NULL, NULL, 5, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '2975FB0F-4AAB-4E8C-B7AB-02DCDA58210B' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = N'descriptionformat'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('2975FB0F-4AAB-4E8C-B7AB-02DCDA58210B', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', N'descriptionformat', N'Description Format', N'Moodle text format code', N'integer', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 6, N'Active');

-- ── User Custom Fields ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' OR (IntegrationID = @IntID AND Name = N'User Custom Fields'))
BEGIN
    DECLARE @ID_dfe89ac4 UNIQUEIDENTIFIER, @Name_dfe89ac4 NVARCHAR(255), @DisplayName_dfe89ac4 NVARCHAR(255),
            @Description_dfe89ac4 NVARCHAR(MAX), @Category_dfe89ac4 NVARCHAR(100), @APIPath_dfe89ac4 NVARCHAR(500),
            @Configuration_dfe89ac4 NVARCHAR(MAX)
    SET @ID_dfe89ac4 = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B'
    SET @Name_dfe89ac4 = N'User Custom Fields'
    SET @DisplayName_dfe89ac4 = N'User Custom Fields'
    SET @Description_dfe89ac4 = N'One row per custom profile field per user, exploded from Users.customfields ({name, shortname, type, value} EAV elements). Profiled live: ~45 distinct shortnames - ~26 stable profile attributes plus per-event CME flags that grow by one per conference, which is exactly why these are rows, not columns.'
    SET @Category_dfe89ac4 = N'Users & Cohorts'
    SET @APIPath_dfe89ac4 = N'/webservice/rest/server.php'
    SET @Configuration_dfe89ac4 = N'{"derivedCollection": {"parentObjectName": "Users", "collectionField": "customfields", "parentKeyMap": {"id": "userid"}, "elementKind": "object"}, "syncStrategy": "Derived: rides the parent object''s fetch (same pagination, parent-scoping and budgets; the parent cursor passes through unchanged) and explodes one array field into child records. FullPullHashDiff like the parent.", "derivationNote": "Exploded from Users.customfields. Measured live 2026-08-19: the array previously landed as one NVARCHAR(MAX) JSON column - present but unqueryable."}'
    EXEC [__mj].spCreateIntegrationObject @ID = @ID_dfe89ac4,
      @IntegrationID = @IntID,
      @Name = @Name_dfe89ac4,
      @DisplayName = @DisplayName_dfe89ac4,
      @Description = @Description_dfe89ac4,
      @Category = @Category_dfe89ac4,
      @APIPath = @APIPath_dfe89ac4,
      @ResponseDataKey = NULL,
      @DefaultPageSize = 0,
      @SupportsPagination = 0,
      @PaginationType = N'None',
      @SupportsIncrementalSync = 0,
      @SupportsWrite = 0,
      @DefaultQueryParams = NULL,
      @Configuration = @Configuration_dfe89ac4,
      @Sequence = 31,
      @Status = N'Active',
      @SupportsCreate = 0,
      @SupportsUpdate = 0,
      @SupportsDelete = 0,
      @MetadataSource = N'Declared'
END
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '5DA4AD9E-0955-4B1F-ACD2-4386EB89FFC6' OR (IntegrationObjectID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' AND Name = N'userid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('5DA4AD9E-0955-4B1F-ACD2-4386EB89FFC6', 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B', N'userid', N'User ID', N'user id (Users.id)', N'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = N'Users'), N'id', 1, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '403DDE3A-5E09-4FCE-94EE-DDDA1CA49AE7' OR (IntegrationObjectID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' AND Name = N'shortname'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('403DDE3A-5E09-4FCE-94EE-DDDA1CA49AE7', 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B', N'shortname', N'Short Name', N'custom field shortname - the stable machine key (e.g. sfid, membertype, 376CME)', N'string', NULL,
     1, 1, 1, 1, 0,
     NULL, NULL, 2, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '46EA4E98-1299-48DB-871B-61D981913B61' OR (IntegrationObjectID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' AND Name = N'name'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('46EA4E98-1299-48DB-871B-61D981913B61', 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B', N'name', N'Name', N'human label of the custom field', N'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 3, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '37AEDFA6-CECA-4E7A-AD6C-B54D715653D1' OR (IntegrationObjectID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' AND Name = N'type'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('37AEDFA6-CECA-4E7A-AD6C-B54D715653D1', 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B', N'type', N'Type', N'declared field type (text, menu, checkbox, datetime, ...)', N'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 4, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '9D32D080-E8A6-4E66-BB67-2680FCD1FB04' OR (IntegrationObjectID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' AND Name = N'value'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('9D32D080-E8A6-4E66-BB67-2680FCD1FB04', 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B', N'value', N'Value', N'the field''s value for this user', N'string', 4000,
     0, 1, 0, 0, 1,
     NULL, NULL, 5, N'Active');

-- ── Course Content Modules ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' OR (IntegrationID = @IntID AND Name = N'Course Content Modules'))
BEGIN
    DECLARE @ID_3e083aeb UNIQUEIDENTIFIER, @Name_3e083aeb NVARCHAR(255), @DisplayName_3e083aeb NVARCHAR(255),
            @Description_3e083aeb NVARCHAR(MAX), @Category_3e083aeb NVARCHAR(100), @APIPath_3e083aeb NVARCHAR(500),
            @Configuration_3e083aeb NVARCHAR(MAX)
    SET @ID_3e083aeb = '3E083AEB-1064-4148-AA38-56FF0E9A7C44'
    SET @Name_3e083aeb = N'Course Content Modules'
    SET @DisplayName_3e083aeb = N'Course Content Modules'
    SET @Description_3e083aeb = N'One row per module (activity/resource) in a course section, exploded from Course Contents.modules. Profiled live at 0-30 modules per section (avg 2.58). The element''s nested `contents` file list stays as JSON text on this row.'
    SET @Category_3e083aeb = N'Courses'
    SET @APIPath_3e083aeb = N'/webservice/rest/server.php'
    SET @Configuration_3e083aeb = N'{"derivedCollection": {"parentObjectName": "Course Contents", "collectionField": "modules", "parentKeyMap": {"id": "sectionid"}, "elementKind": "object"}, "syncStrategy": "Derived: rides the parent object''s fetch (same pagination, parent-scoping and budgets; the parent cursor passes through unchanged) and explodes one array field into child records. FullPullHashDiff like the parent.", "derivationNote": "Exploded from Course Contents.modules. Measured live 2026-08-19: the array previously landed as one NVARCHAR(MAX) JSON column - present but unqueryable."}'
    EXEC [__mj].spCreateIntegrationObject @ID = @ID_3e083aeb,
      @IntegrationID = @IntID,
      @Name = @Name_3e083aeb,
      @DisplayName = @DisplayName_3e083aeb,
      @Description = @Description_3e083aeb,
      @Category = @Category_3e083aeb,
      @APIPath = @APIPath_3e083aeb,
      @ResponseDataKey = NULL,
      @DefaultPageSize = 0,
      @SupportsPagination = 0,
      @PaginationType = N'None',
      @SupportsIncrementalSync = 0,
      @SupportsWrite = 0,
      @DefaultQueryParams = NULL,
      @Configuration = @Configuration_3e083aeb,
      @Sequence = 32,
      @Status = N'Active',
      @SupportsCreate = 0,
      @SupportsUpdate = 0,
      @SupportsDelete = 0,
      @MetadataSource = N'Declared'
END
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'DD63DCE3-754C-48B7-AB03-7B131386B6E0' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'id'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('DD63DCE3-754C-48B7-AB03-7B131386B6E0', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'id', N'Module ID', N'course-module id (globally unique in Totara)', N'integer', NULL,
     1, 1, 1, 1, 0,
     NULL, NULL, 1, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'F61AED0A-F8BC-4DB0-AAE6-9CD834EC7BE7' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'sectionid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('F61AED0A-F8BC-4DB0-AAE6-9CD834EC7BE7', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'sectionid', N'Section ID', N'course section id (Course Contents.id)', N'integer', NULL,
     0, 1, 0, 0, 1,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = N'Course Contents'), N'id', 2, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '96A54CC7-0164-4C75-ADC5-7120AAFD7785' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'name'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('96A54CC7-0164-4C75-ADC5-7120AAFD7785', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'name', N'Name', N'module name', N'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 3, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '0A6EC225-5404-4F41-8844-C383725D9BBE' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'modname'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('0A6EC225-5404-4F41-8844-C383725D9BBE', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'modname', N'Module Type', N'module type shortname (assign, quiz, resource, ...)', N'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 4, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'BA352C29-23BD-4D69-A6C6-88D971843F44' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'modplural'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('BA352C29-23BD-4D69-A6C6-88D971843F44', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'modplural', N'Module Type Plural', N'plural label of the module type', N'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 5, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'B71290B2-E720-486F-9FDC-660A377672B6' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'instance'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('B71290B2-E720-486F-9FDC-660A377672B6', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'instance', N'Instance ID', N'id of the module-type-specific instance row', N'integer', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 6, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '145EA107-1E20-4061-9888-A8B106115F20' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'visible'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('145EA107-1E20-4061-9888-A8B106115F20', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'visible', N'Visible', N'visibility flag', N'integer', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 7, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '0E325FCE-2760-4939-ADCC-E806F1ED7ABE' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'indent'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('0E325FCE-2760-4939-ADCC-E806F1ED7ABE', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'indent', N'Indent', N'display indent level', N'integer', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 8, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '804349D5-94C9-4FE9-82D2-A0F7B9E17890' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'url'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('804349D5-94C9-4FE9-82D2-A0F7B9E17890', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'url', N'URL', N'module view URL', N'string', 2048,
     0, 1, 0, 0, 1,
     NULL, NULL, 9, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '5E5F9478-482D-4DB0-9598-AB978151D839' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'description'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('5E5F9478-482D-4DB0-9598-AB978151D839', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'description', N'Description', N'module description HTML', N'string', 4000,
     0, 1, 0, 0, 1,
     NULL, NULL, 10, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '6D13F1EC-0A3E-487D-BB8E-490AE98026B2' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'availability'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('6D13F1EC-0A3E-487D-BB8E-490AE98026B2', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'availability', N'Availability', N'availability condition JSON (as text)', N'json', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 11, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '7BC98D44-4D7E-4890-9288-560B35F43459' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = N'contents'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('7BC98D44-4D7E-4890-9288-560B35F43459', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', N'contents', N'Contents', N'nested contents/file list, retained as JSON text', N'json', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 12, N'Active');

-- ── Cohort Member Users ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = '73F050B1-8B5F-4C27-83C9-838477B71EB9' OR (IntegrationID = @IntID AND Name = N'Cohort Member Users'))
BEGIN
    DECLARE @ID_73f050b1 UNIQUEIDENTIFIER, @Name_73f050b1 NVARCHAR(255), @DisplayName_73f050b1 NVARCHAR(255),
            @Description_73f050b1 NVARCHAR(MAX), @Category_73f050b1 NVARCHAR(100), @APIPath_73f050b1 NVARCHAR(500),
            @Configuration_73f050b1 NVARCHAR(MAX)
    SET @ID_73f050b1 = '73F050B1-8B5F-4C27-83C9-838477B71EB9'
    SET @Name_73f050b1 = N'Cohort Member Users'
    SET @DisplayName_73f050b1 = N'Cohort Member Users'
    SET @Description_73f050b1 = N'One row per (cohort, user) membership, exploded from Cohort Members.userids - a bare id array profiled live at up to 12,697 elements on a single row.'
    SET @Category_73f050b1 = N'Users & Cohorts'
    SET @APIPath_73f050b1 = N'/webservice/rest/server.php'
    SET @Configuration_73f050b1 = N'{"derivedCollection": {"parentObjectName": "Cohort Members", "collectionField": "userids", "parentKeyMap": {"cohortid": "cohortid"}, "elementKind": "scalar", "scalarFieldName": "userid"}, "syncStrategy": "Derived: rides the parent object''s fetch (same pagination, parent-scoping and budgets; the parent cursor passes through unchanged) and explodes one array field into child records. FullPullHashDiff like the parent.", "derivationNote": "Exploded from Cohort Members.userids. Measured live 2026-08-19: the array previously landed as one NVARCHAR(MAX) JSON column - present but unqueryable."}'
    EXEC [__mj].spCreateIntegrationObject @ID = @ID_73f050b1,
      @IntegrationID = @IntID,
      @Name = @Name_73f050b1,
      @DisplayName = @DisplayName_73f050b1,
      @Description = @Description_73f050b1,
      @Category = @Category_73f050b1,
      @APIPath = @APIPath_73f050b1,
      @ResponseDataKey = NULL,
      @DefaultPageSize = 0,
      @SupportsPagination = 0,
      @PaginationType = N'None',
      @SupportsIncrementalSync = 0,
      @SupportsWrite = 0,
      @DefaultQueryParams = NULL,
      @Configuration = @Configuration_73f050b1,
      @Sequence = 33,
      @Status = N'Active',
      @SupportsCreate = 0,
      @SupportsUpdate = 0,
      @SupportsDelete = 0,
      @MetadataSource = N'Declared'
END
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'A6AB9B9E-8387-40ED-B807-D870AD0903D1' OR (IntegrationObjectID = '73F050B1-8B5F-4C27-83C9-838477B71EB9' AND Name = N'cohortid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('A6AB9B9E-8387-40ED-B807-D870AD0903D1', '73F050B1-8B5F-4C27-83C9-838477B71EB9', N'cohortid', N'Cohort ID', N'cohort id (Cohort Members.cohortid)', N'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = N'Cohorts'), N'id', 1, N'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '4A017709-29D8-4426-8AD1-E731D36E3D0E' OR (IntegrationObjectID = '73F050B1-8B5F-4C27-83C9-838477B71EB9' AND Name = N'userid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('4A017709-29D8-4426-8AD1-E731D36E3D0E', '73F050B1-8B5F-4C27-83C9-838477B71EB9', N'userid', N'User ID', N'member user id (one array element)', N'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = N'Users'), N'id', 2, N'Active');

-- dropFields on Users: configuration payload, not data — see header.
UPDATE [__mj].IntegrationObject
SET Configuration = JSON_MODIFY(Configuration, '$.dropFields', JSON_QUERY(N'["preferences"]'))
WHERE IntegrationID = @IntID AND Name = N'Users'
  AND Configuration NOT LIKE '%"dropFields"%';

-- dropFields on Enrolled Users: configuration payload, not data — see header.
UPDATE [__mj].IntegrationObject
SET Configuration = JSON_MODIFY(Configuration, '$.dropFields', JSON_QUERY(N'["preferences"]'))
WHERE IntegrationID = @IntID AND Name = N'Enrolled Users'
  AND Configuration NOT LIKE '%"dropFields"%';

-- dropFields on Courses: configuration payload, not data — see header.
UPDATE [__mj].IntegrationObject
SET Configuration = JSON_MODIFY(Configuration, '$.dropFields', JSON_QUERY(N'["courseformatoptions"]'))
WHERE IntegrationID = @IntID AND Name = N'Courses'
  AND Configuration NOT LIKE '%"dropFields"%';
