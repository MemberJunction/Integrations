-- Totara: five derived child objects — the embedded JSON arrays become first-class tables.
--
-- Profiled live (2026-08-19): Enrolled_Users.roles / .groups, Users.customfields,
-- Course_Contents.modules and Cohort_Members.userids each landed as one NVARCHAR(MAX)
-- column of JSON text — present, but unqueryable. Each becomes a derived object whose
-- fetch is served from the PARENT object's own walk, as the data comes in (see
-- Configuration.derivedCollection and src/DerivedCollections.ts). No engine change.
--
-- Also declares Configuration.dropFields on Users / Enrolled Users / Courses:
-- `preferences` (Moodle UI widget state — the same nine keys on 100% of rows) and
-- `courseformatoptions` (course theming) are configuration, not data, and stop being
-- fetched. Existing columns are untouched and simply stop being written.
--
-- Delta migration: INSERTs are guarded (skip when the ID or (IntegrationID, Name)
-- already exists) and the Configuration updates are guarded on the key being absent,
-- so re-running is a no-op. IDs match metadata primaryKey.ID exactly.

DECLARE @IntID UNIQUEIDENTIFIER = (SELECT ID FROM [__mj].Integration WHERE Name = 'totara');

-- ── Enrolled User Roles ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' OR (IntegrationID = @IntID AND Name = 'Enrolled User Roles'))
INSERT INTO [__mj].IntegrationObject
    (ID, IntegrationID, Name, DisplayName, Description, Category, APIPath, ResponseDataKey,
     SupportsPagination, PaginationType, SupportsIncrementalSync, SupportsWrite,
     Configuration, Sequence, Status, SupportsCreate, SupportsUpdate, SupportsDelete, MetadataSource)
VALUES
    ('E3F16EBC-DD27-4924-98D5-D26D4AE495F8', @IntID, 'Enrolled User Roles', 'Enrolled User Roles', 'One row per role a user holds in a course, exploded from Enrolled Users.roles. Previously a JSON array column; profiled live at 0-3 elements per enrolment (avg 1.10).', 'Users & Cohorts',
     '/webservice/rest/server.php', NULL, 0, 'None', 0, 0,
     N'{"derivedCollection": {"parentObjectName": "Enrolled Users", "collectionField": "roles", "parentKeyMap": {"id": "userid", "courseid": "courseid"}, "elementKind": "object"}, "syncStrategy": "Derived: rides the parent object''s fetch (same pagination, parent-scoping and budgets; the parent cursor passes through unchanged) and explodes one array field into child records. FullPullHashDiff like the parent.", "derivationNote": "Exploded from Enrolled Users.roles. Measured live 2026-08-19: the array previously landed as one NVARCHAR(MAX) JSON column - present but unqueryable."}', 29, 'Active', 0, 0, 0, 'Declared');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '464CBE3D-6C4A-4C6C-9662-CCC5D423B39B' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = 'userid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('464CBE3D-6C4A-4C6C-9662-CCC5D423B39B', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', 'userid', 'User ID', 'user id (Enrolled Users.id, renamed to avoid colliding with the element)', 'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = 'Users'), 'id', 1, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'D46C15C8-8700-4019-9EE3-CBC92655F0DC' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = 'courseid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('D46C15C8-8700-4019-9EE3-CBC92655F0DC', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', 'courseid', 'Course ID', 'course the role applies in', 'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = 'Courses'), 'id', 2, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '60F414FE-6F18-4424-A1E6-BB94028C8946' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = 'roleid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('60F414FE-6F18-4424-A1E6-BB94028C8946', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', 'roleid', 'Role ID', 'Totara role id', 'integer', NULL,
     1, 1, 1, 1, 0,
     NULL, NULL, 3, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'F22904FC-6FA4-48A2-89EF-C2F71E4A791A' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = 'shortname'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('F22904FC-6FA4-48A2-89EF-C2F71E4A791A', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', 'shortname', 'Short Name', 'role shortname (e.g. student, editingteacher)', 'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 4, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '68D5A506-ADB0-40E5-9457-BD564C9582F8' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = 'name'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('68D5A506-ADB0-40E5-9457-BD564C9582F8', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', 'name', 'Name', 'role display name', 'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 5, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'ABC9D9A1-07D6-42B1-BDD8-EB3310CEBA2C' OR (IntegrationObjectID = 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8' AND Name = 'sortorder'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('ABC9D9A1-07D6-42B1-BDD8-EB3310CEBA2C', 'E3F16EBC-DD27-4924-98D5-D26D4AE495F8', 'sortorder', 'Sort Order', 'role sort order', 'integer', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 6, 'Active');

-- ── Enrolled User Groups ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' OR (IntegrationID = @IntID AND Name = 'Enrolled User Groups'))
INSERT INTO [__mj].IntegrationObject
    (ID, IntegrationID, Name, DisplayName, Description, Category, APIPath, ResponseDataKey,
     SupportsPagination, PaginationType, SupportsIncrementalSync, SupportsWrite,
     Configuration, Sequence, Status, SupportsCreate, SupportsUpdate, SupportsDelete, MetadataSource)
VALUES
    ('51F83BA6-CCE7-447B-826D-DECE9DC39B26', @IntID, 'Enrolled User Groups', 'Enrolled User Groups', 'One row per group membership within a course, exploded from Enrolled Users.groups. Element id is the GROUP id and is renamed groupid.', 'Users & Cohorts',
     '/webservice/rest/server.php', NULL, 0, 'None', 0, 0,
     N'{"derivedCollection": {"parentObjectName": "Enrolled Users", "collectionField": "groups", "parentKeyMap": {"id": "userid", "courseid": "courseid"}, "elementKind": "object", "elementKeyMap": {"id": "groupid"}}, "syncStrategy": "Derived: rides the parent object''s fetch (same pagination, parent-scoping and budgets; the parent cursor passes through unchanged) and explodes one array field into child records. FullPullHashDiff like the parent.", "derivationNote": "Exploded from Enrolled Users.groups. Measured live 2026-08-19: the array previously landed as one NVARCHAR(MAX) JSON column - present but unqueryable."}', 30, 'Active', 0, 0, 0, 'Declared');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'F9DD45FE-804E-48BB-93DC-A78E3A84DC8E' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = 'userid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('F9DD45FE-804E-48BB-93DC-A78E3A84DC8E', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', 'userid', 'User ID', 'user id (Enrolled Users.id)', 'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = 'Users'), 'id', 1, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '9094721F-A99D-400F-B8B2-57F0CE0AFB01' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = 'courseid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('9094721F-A99D-400F-B8B2-57F0CE0AFB01', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', 'courseid', 'Course ID', 'course the group belongs to', 'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = 'Courses'), 'id', 2, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '85B56C12-D5DA-402E-ACE4-4B994B1D23A8' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = 'groupid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('85B56C12-D5DA-402E-ACE4-4B994B1D23A8', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', 'groupid', 'Group ID', 'group id (element id, renamed)', 'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = 'Groups'), 'id', 3, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'C859B98A-41B3-45BA-AF05-A2A777B0932F' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = 'name'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('C859B98A-41B3-45BA-AF05-A2A777B0932F', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', 'name', 'Name', 'group name', 'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 4, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '2994EE74-D5AE-4E3E-8DE0-61937438FB1E' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = 'description'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('2994EE74-D5AE-4E3E-8DE0-61937438FB1E', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', 'description', 'Description', 'group description', 'string', 4000,
     0, 1, 0, 0, 1,
     NULL, NULL, 5, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '2975FB0F-4AAB-4E8C-B7AB-02DCDA58210B' OR (IntegrationObjectID = '51F83BA6-CCE7-447B-826D-DECE9DC39B26' AND Name = 'descriptionformat'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('2975FB0F-4AAB-4E8C-B7AB-02DCDA58210B', '51F83BA6-CCE7-447B-826D-DECE9DC39B26', 'descriptionformat', 'Description Format', 'Moodle text format code', 'integer', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 6, 'Active');

-- ── User Custom Fields ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' OR (IntegrationID = @IntID AND Name = 'User Custom Fields'))
INSERT INTO [__mj].IntegrationObject
    (ID, IntegrationID, Name, DisplayName, Description, Category, APIPath, ResponseDataKey,
     SupportsPagination, PaginationType, SupportsIncrementalSync, SupportsWrite,
     Configuration, Sequence, Status, SupportsCreate, SupportsUpdate, SupportsDelete, MetadataSource)
VALUES
    ('DFE89AC4-62E8-4923-AD18-1D947A99EB0B', @IntID, 'User Custom Fields', 'User Custom Fields', 'One row per custom profile field per user, exploded from Users.customfields ({name, shortname, type, value} EAV elements). Profiled live: ~45 distinct shortnames - ~26 stable profile attributes plus per-event CME flags that grow by one per conference, which is exactly why these are rows, not columns.', 'Users & Cohorts',
     '/webservice/rest/server.php', NULL, 0, 'None', 0, 0,
     N'{"derivedCollection": {"parentObjectName": "Users", "collectionField": "customfields", "parentKeyMap": {"id": "userid"}, "elementKind": "object"}, "syncStrategy": "Derived: rides the parent object''s fetch (same pagination, parent-scoping and budgets; the parent cursor passes through unchanged) and explodes one array field into child records. FullPullHashDiff like the parent.", "derivationNote": "Exploded from Users.customfields. Measured live 2026-08-19: the array previously landed as one NVARCHAR(MAX) JSON column - present but unqueryable."}', 31, 'Active', 0, 0, 0, 'Declared');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '5DA4AD9E-0955-4B1F-ACD2-4386EB89FFC6' OR (IntegrationObjectID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' AND Name = 'userid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('5DA4AD9E-0955-4B1F-ACD2-4386EB89FFC6', 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B', 'userid', 'User ID', 'user id (Users.id)', 'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = 'Users'), 'id', 1, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '403DDE3A-5E09-4FCE-94EE-DDDA1CA49AE7' OR (IntegrationObjectID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' AND Name = 'shortname'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('403DDE3A-5E09-4FCE-94EE-DDDA1CA49AE7', 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B', 'shortname', 'Short Name', 'custom field shortname - the stable machine key (e.g. sfid, membertype, 376CME)', 'string', NULL,
     1, 1, 1, 1, 0,
     NULL, NULL, 2, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '46EA4E98-1299-48DB-871B-61D981913B61' OR (IntegrationObjectID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' AND Name = 'name'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('46EA4E98-1299-48DB-871B-61D981913B61', 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B', 'name', 'Name', 'human label of the custom field', 'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 3, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '37AEDFA6-CECA-4E7A-AD6C-B54D715653D1' OR (IntegrationObjectID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' AND Name = 'type'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('37AEDFA6-CECA-4E7A-AD6C-B54D715653D1', 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B', 'type', 'Type', 'declared field type (text, menu, checkbox, datetime, ...)', 'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 4, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '9D32D080-E8A6-4E66-BB67-2680FCD1FB04' OR (IntegrationObjectID = 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B' AND Name = 'value'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('9D32D080-E8A6-4E66-BB67-2680FCD1FB04', 'DFE89AC4-62E8-4923-AD18-1D947A99EB0B', 'value', 'Value', 'the field''s value for this user', 'string', 4000,
     0, 1, 0, 0, 1,
     NULL, NULL, 5, 'Active');

-- ── Course Content Modules ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' OR (IntegrationID = @IntID AND Name = 'Course Content Modules'))
INSERT INTO [__mj].IntegrationObject
    (ID, IntegrationID, Name, DisplayName, Description, Category, APIPath, ResponseDataKey,
     SupportsPagination, PaginationType, SupportsIncrementalSync, SupportsWrite,
     Configuration, Sequence, Status, SupportsCreate, SupportsUpdate, SupportsDelete, MetadataSource)
VALUES
    ('3E083AEB-1064-4148-AA38-56FF0E9A7C44', @IntID, 'Course Content Modules', 'Course Content Modules', 'One row per module (activity/resource) in a course section, exploded from Course Contents.modules. Profiled live at 0-30 modules per section (avg 2.58). The element''s nested `contents` file list stays as JSON text on this row.', 'Courses',
     '/webservice/rest/server.php', NULL, 0, 'None', 0, 0,
     N'{"derivedCollection": {"parentObjectName": "Course Contents", "collectionField": "modules", "parentKeyMap": {"id": "sectionid"}, "elementKind": "object"}, "syncStrategy": "Derived: rides the parent object''s fetch (same pagination, parent-scoping and budgets; the parent cursor passes through unchanged) and explodes one array field into child records. FullPullHashDiff like the parent.", "derivationNote": "Exploded from Course Contents.modules. Measured live 2026-08-19: the array previously landed as one NVARCHAR(MAX) JSON column - present but unqueryable."}', 32, 'Active', 0, 0, 0, 'Declared');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'DD63DCE3-754C-48B7-AB03-7B131386B6E0' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'id'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('DD63DCE3-754C-48B7-AB03-7B131386B6E0', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'id', 'Module ID', 'course-module id (globally unique in Totara)', 'integer', NULL,
     1, 1, 1, 1, 0,
     NULL, NULL, 1, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'F61AED0A-F8BC-4DB0-AAE6-9CD834EC7BE7' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'sectionid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('F61AED0A-F8BC-4DB0-AAE6-9CD834EC7BE7', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'sectionid', 'Section ID', 'course section id (Course Contents.id)', 'integer', NULL,
     0, 1, 0, 0, 1,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = 'Course Contents'), 'id', 2, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '96A54CC7-0164-4C75-ADC5-7120AAFD7785' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'name'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('96A54CC7-0164-4C75-ADC5-7120AAFD7785', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'name', 'Name', 'module name', 'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 3, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '0A6EC225-5404-4F41-8844-C383725D9BBE' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'modname'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('0A6EC225-5404-4F41-8844-C383725D9BBE', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'modname', 'Module Type', 'module type shortname (assign, quiz, resource, ...)', 'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 4, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'BA352C29-23BD-4D69-A6C6-88D971843F44' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'modplural'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('BA352C29-23BD-4D69-A6C6-88D971843F44', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'modplural', 'Module Type Plural', 'plural label of the module type', 'string', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 5, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'B71290B2-E720-486F-9FDC-660A377672B6' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'instance'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('B71290B2-E720-486F-9FDC-660A377672B6', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'instance', 'Instance ID', 'id of the module-type-specific instance row', 'integer', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 6, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '145EA107-1E20-4061-9888-A8B106115F20' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'visible'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('145EA107-1E20-4061-9888-A8B106115F20', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'visible', 'Visible', 'visibility flag', 'integer', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 7, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '0E325FCE-2760-4939-ADCC-E806F1ED7ABE' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'indent'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('0E325FCE-2760-4939-ADCC-E806F1ED7ABE', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'indent', 'Indent', 'display indent level', 'integer', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 8, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '804349D5-94C9-4FE9-82D2-A0F7B9E17890' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'url'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('804349D5-94C9-4FE9-82D2-A0F7B9E17890', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'url', 'URL', 'module view URL', 'string', 2048,
     0, 1, 0, 0, 1,
     NULL, NULL, 9, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '5E5F9478-482D-4DB0-9598-AB978151D839' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'description'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('5E5F9478-482D-4DB0-9598-AB978151D839', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'description', 'Description', 'module description HTML', 'string', 4000,
     0, 1, 0, 0, 1,
     NULL, NULL, 10, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '6D13F1EC-0A3E-487D-BB8E-490AE98026B2' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'availability'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('6D13F1EC-0A3E-487D-BB8E-490AE98026B2', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'availability', 'Availability', 'availability condition JSON (as text)', 'json', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 11, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '7BC98D44-4D7E-4890-9288-560B35F43459' OR (IntegrationObjectID = '3E083AEB-1064-4148-AA38-56FF0E9A7C44' AND Name = 'contents'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('7BC98D44-4D7E-4890-9288-560B35F43459', '3E083AEB-1064-4148-AA38-56FF0E9A7C44', 'contents', 'Contents', 'nested contents/file list, retained as JSON text', 'json', NULL,
     0, 1, 0, 0, 1,
     NULL, NULL, 12, 'Active');

-- ── Cohort Member Users ─────────────────────────────────────────────
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObject WHERE ID = '73F050B1-8B5F-4C27-83C9-838477B71EB9' OR (IntegrationID = @IntID AND Name = 'Cohort Member Users'))
INSERT INTO [__mj].IntegrationObject
    (ID, IntegrationID, Name, DisplayName, Description, Category, APIPath, ResponseDataKey,
     SupportsPagination, PaginationType, SupportsIncrementalSync, SupportsWrite,
     Configuration, Sequence, Status, SupportsCreate, SupportsUpdate, SupportsDelete, MetadataSource)
VALUES
    ('73F050B1-8B5F-4C27-83C9-838477B71EB9', @IntID, 'Cohort Member Users', 'Cohort Member Users', 'One row per (cohort, user) membership, exploded from Cohort Members.userids - a bare id array profiled live at up to 12,697 elements on a single row.', 'Users & Cohorts',
     '/webservice/rest/server.php', NULL, 0, 'None', 0, 0,
     N'{"derivedCollection": {"parentObjectName": "Cohort Members", "collectionField": "userids", "parentKeyMap": {"cohortid": "cohortid"}, "elementKind": "scalar", "scalarFieldName": "userid"}, "syncStrategy": "Derived: rides the parent object''s fetch (same pagination, parent-scoping and budgets; the parent cursor passes through unchanged) and explodes one array field into child records. FullPullHashDiff like the parent.", "derivationNote": "Exploded from Cohort Members.userids. Measured live 2026-08-19: the array previously landed as one NVARCHAR(MAX) JSON column - present but unqueryable."}', 33, 'Active', 0, 0, 0, 'Declared');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = 'A6AB9B9E-8387-40ED-B807-D870AD0903D1' OR (IntegrationObjectID = '73F050B1-8B5F-4C27-83C9-838477B71EB9' AND Name = 'cohortid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('A6AB9B9E-8387-40ED-B807-D870AD0903D1', '73F050B1-8B5F-4C27-83C9-838477B71EB9', 'cohortid', 'Cohort ID', 'cohort id (Cohort Members.cohortid)', 'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = 'Cohorts'), 'id', 1, 'Active');
IF NOT EXISTS (SELECT 1 FROM [__mj].IntegrationObjectField WHERE ID = '4A017709-29D8-4426-8AD1-E731D36E3D0E' OR (IntegrationObjectID = '73F050B1-8B5F-4C27-83C9-838477B71EB9' AND Name = 'userid'))
INSERT INTO [__mj].IntegrationObjectField
    (ID, IntegrationObjectID, Name, DisplayName, Description, Type, Length,
     IsRequired, IsReadOnly, IsPrimaryKey, IsUniqueKey, AllowsNull,
     RelatedIntegrationObjectID, RelatedIntegrationObjectFieldName, Sequence, Status)
VALUES
    ('4A017709-29D8-4426-8AD1-E731D36E3D0E', '73F050B1-8B5F-4C27-83C9-838477B71EB9', 'userid', 'User ID', 'member user id (one array element)', 'integer', NULL,
     1, 1, 1, 1, 0,
     (SELECT ID FROM [__mj].IntegrationObject WHERE IntegrationID = @IntID AND Name = 'Users'), 'id', 2, 'Active');

-- dropFields on Users: configuration payload, not data — see header.
UPDATE [__mj].IntegrationObject
SET Configuration = JSON_MODIFY(Configuration, '$.dropFields', JSON_QUERY(N'["preferences"]'))
WHERE IntegrationID = @IntID AND Name = 'Users'
  AND Configuration NOT LIKE '%"dropFields"%';

-- dropFields on Enrolled Users: configuration payload, not data — see header.
UPDATE [__mj].IntegrationObject
SET Configuration = JSON_MODIFY(Configuration, '$.dropFields', JSON_QUERY(N'["preferences"]'))
WHERE IntegrationID = @IntID AND Name = 'Enrolled Users'
  AND Configuration NOT LIKE '%"dropFields"%';

-- dropFields on Courses: configuration payload, not data — see header.
UPDATE [__mj].IntegrationObject
SET Configuration = JSON_MODIFY(Configuration, '$.dropFields', JSON_QUERY(N'["courseformatoptions"]'))
WHERE IntegrationID = @IntID AND Name = 'Courses'
  AND Configuration NOT LIKE '%"dropFields"%';
