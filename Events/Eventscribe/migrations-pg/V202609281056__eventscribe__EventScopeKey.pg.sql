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

-- Eventscribe Connector — key each event's records apart: an EventScope field on every active object.
--
-- All connections of one connector write into the same tables, and the engine matches an incoming row to
-- an existing one by the entity's primary key across the WHOLE table. Every key here was a Cadmium id
-- alone, so a client with one connection per product per event (SCORECARD 2025, SCORECARD 2026, ...)
-- got one row per id: the same author, presenter or exhibitor in two events became a single row holding
-- whichever event synced last.
--
-- This adds `EventScope` to each of the 22 active objects. The connector stamps it on every record it
-- reads: the connection's configured eID, or, when the connection sets none, the connection's own ID, so
-- two connections can never share a value unless they name the same event. On the 17 keyed objects it
-- joins the declared primary key, which becomes (Cadmium id, EventScope); on the five keyless objects it
-- is a plain column that enters the record's content hash. The field's Configuration carries the
-- `connectorStamped: "event-scope"` marker the connector keys on. The 16 disabled EdgeReg objects are
-- untouched.
--
-- Only new rows: no existing field changes, so nothing here can conflict with a tenant's edits. Each
-- block is in the exact form `mj sync push` emits for ../metadata (the renderer that wrote them
-- reproduces all 658 field blocks of V202608271153 byte for byte from the same metadata). IDs are
-- hardcoded; audit columns are not set.

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c4be2d1d UUID;
  p_IntegrationObjectID_c4be2d1d UUID;
  p_Name_c4be2d1d VARCHAR(255);
  p_DisplayName_c4be2d1d VARCHAR(255);
  p_Description_c4be2d1d TEXT;
  p_Category_c4be2d1d VARCHAR(100);
  p_Type_c4be2d1d VARCHAR(100);
  p_Length_c4be2d1d INTEGER;
  p_Precision_c4be2d1d INTEGER;
  p_Scale_c4be2d1d INTEGER;
  p_AllowsNull_c4be2d1d BOOLEAN;
  p_DefaultValue_c4be2d1d VARCHAR(255);
  p_IsPrimaryKey_c4be2d1d BOOLEAN;
  p_IsUniqueKey_c4be2d1d BOOLEAN;
  p_IsReadOnly_c4be2d1d BOOLEAN;
  p_IsRequired_c4be2d1d BOOLEAN;
  p_RelatedIntegrationObjectID_c4be2d1d UUID;
  p_RelatedIntegrationObjectFieldName_c4be2d1d VARCHAR(255);
  p_Sequence_c4be2d1d INTEGER;
  p_Configuration_c4be2d1d TEXT;
  p_Status_c4be2d1d VARCHAR(25);
  p_IsCustom_c4be2d1d BOOLEAN;
  p_MetadataSource_c4be2d1d VARCHAR(20);
BEGIN
  p_ID_c4be2d1d := 'E3C185CD-EC7D-4BE6-A498-FE16FCD03B0C';
  p_IntegrationObjectID_c4be2d1d := '5C5C0615-17CD-4AF0-9ED0-5EC68CA5B3E5';
  p_Name_c4be2d1d := 'EventScope';
  p_DisplayName_c4be2d1d := 'Event Scope';
  p_Description_c4be2d1d := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_c4be2d1d := 'Identity';
  p_Type_c4be2d1d := 'TEXT';
  p_Length_c4be2d1d := 100;
  p_AllowsNull_c4be2d1d := FALSE;
  p_IsPrimaryKey_c4be2d1d := TRUE;
  p_IsUniqueKey_c4be2d1d := FALSE;
  p_IsReadOnly_c4be2d1d := TRUE;
  p_IsRequired_c4be2d1d := FALSE;
  p_Sequence_c4be2d1d := 62;
  p_Configuration_c4be2d1d := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_c4be2d1d := 'Active';
  p_IsCustom_c4be2d1d := FALSE;
  p_MetadataSource_c4be2d1d := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c4be2d1d, p_IntegrationObjectID := p_IntegrationObjectID_c4be2d1d, p_Name := p_Name_c4be2d1d, p_DisplayName := p_DisplayName_c4be2d1d, p_Description := p_Description_c4be2d1d, p_Category := p_Category_c4be2d1d, p_Type := p_Type_c4be2d1d, p_Length := p_Length_c4be2d1d, p_Precision := p_Precision_c4be2d1d, p_Precision_Clear := TRUE, p_Scale := p_Scale_c4be2d1d, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c4be2d1d, p_DefaultValue := p_DefaultValue_c4be2d1d, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c4be2d1d, p_IsUniqueKey := p_IsUniqueKey_c4be2d1d, p_IsReadOnly := p_IsReadOnly_c4be2d1d, p_IsRequired := p_IsRequired_c4be2d1d, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c4be2d1d, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c4be2d1d, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c4be2d1d, p_Configuration := p_Configuration_c4be2d1d, p_Status := p_Status_c4be2d1d, p_IsCustom := p_IsCustom_c4be2d1d, p_MetadataSource := p_MetadataSource_c4be2d1d);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_ebc5a6a0 UUID;
  p_IntegrationObjectID_ebc5a6a0 UUID;
  p_Name_ebc5a6a0 VARCHAR(255);
  p_DisplayName_ebc5a6a0 VARCHAR(255);
  p_Description_ebc5a6a0 TEXT;
  p_Category_ebc5a6a0 VARCHAR(100);
  p_Type_ebc5a6a0 VARCHAR(100);
  p_Length_ebc5a6a0 INTEGER;
  p_Precision_ebc5a6a0 INTEGER;
  p_Scale_ebc5a6a0 INTEGER;
  p_AllowsNull_ebc5a6a0 BOOLEAN;
  p_DefaultValue_ebc5a6a0 VARCHAR(255);
  p_IsPrimaryKey_ebc5a6a0 BOOLEAN;
  p_IsUniqueKey_ebc5a6a0 BOOLEAN;
  p_IsReadOnly_ebc5a6a0 BOOLEAN;
  p_IsRequired_ebc5a6a0 BOOLEAN;
  p_RelatedIntegrationObjectID_ebc5a6a0 UUID;
  p_RelatedIntegrationObjectFieldName_ebc5a6a0 VARCHAR(255);
  p_Sequence_ebc5a6a0 INTEGER;
  p_Configuration_ebc5a6a0 TEXT;
  p_Status_ebc5a6a0 VARCHAR(25);
  p_IsCustom_ebc5a6a0 BOOLEAN;
  p_MetadataSource_ebc5a6a0 VARCHAR(20);
BEGIN
  p_ID_ebc5a6a0 := '917726C7-E9CB-4FED-BB24-3BEB83EFF8C1';
  p_IntegrationObjectID_ebc5a6a0 := 'B55EDFE8-86D5-4BC2-BA51-2D584CA98D3A';
  p_Name_ebc5a6a0 := 'EventScope';
  p_DisplayName_ebc5a6a0 := 'Event Scope';
  p_Description_ebc5a6a0 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_ebc5a6a0 := 'Identity';
  p_Type_ebc5a6a0 := 'TEXT';
  p_Length_ebc5a6a0 := 100;
  p_AllowsNull_ebc5a6a0 := FALSE;
  p_IsPrimaryKey_ebc5a6a0 := TRUE;
  p_IsUniqueKey_ebc5a6a0 := FALSE;
  p_IsReadOnly_ebc5a6a0 := TRUE;
  p_IsRequired_ebc5a6a0 := FALSE;
  p_Sequence_ebc5a6a0 := 63;
  p_Configuration_ebc5a6a0 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_ebc5a6a0 := 'Active';
  p_IsCustom_ebc5a6a0 := FALSE;
  p_MetadataSource_ebc5a6a0 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_ebc5a6a0, p_IntegrationObjectID := p_IntegrationObjectID_ebc5a6a0, p_Name := p_Name_ebc5a6a0, p_DisplayName := p_DisplayName_ebc5a6a0, p_Description := p_Description_ebc5a6a0, p_Category := p_Category_ebc5a6a0, p_Type := p_Type_ebc5a6a0, p_Length := p_Length_ebc5a6a0, p_Precision := p_Precision_ebc5a6a0, p_Precision_Clear := TRUE, p_Scale := p_Scale_ebc5a6a0, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_ebc5a6a0, p_DefaultValue := p_DefaultValue_ebc5a6a0, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_ebc5a6a0, p_IsUniqueKey := p_IsUniqueKey_ebc5a6a0, p_IsReadOnly := p_IsReadOnly_ebc5a6a0, p_IsRequired := p_IsRequired_ebc5a6a0, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_ebc5a6a0, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_ebc5a6a0, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_ebc5a6a0, p_Configuration := p_Configuration_ebc5a6a0, p_Status := p_Status_ebc5a6a0, p_IsCustom := p_IsCustom_ebc5a6a0, p_MetadataSource := p_MetadataSource_ebc5a6a0);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_877da73c UUID;
  p_IntegrationObjectID_877da73c UUID;
  p_Name_877da73c VARCHAR(255);
  p_DisplayName_877da73c VARCHAR(255);
  p_Description_877da73c TEXT;
  p_Category_877da73c VARCHAR(100);
  p_Type_877da73c VARCHAR(100);
  p_Length_877da73c INTEGER;
  p_Precision_877da73c INTEGER;
  p_Scale_877da73c INTEGER;
  p_AllowsNull_877da73c BOOLEAN;
  p_DefaultValue_877da73c VARCHAR(255);
  p_IsPrimaryKey_877da73c BOOLEAN;
  p_IsUniqueKey_877da73c BOOLEAN;
  p_IsReadOnly_877da73c BOOLEAN;
  p_IsRequired_877da73c BOOLEAN;
  p_RelatedIntegrationObjectID_877da73c UUID;
  p_RelatedIntegrationObjectFieldName_877da73c VARCHAR(255);
  p_Sequence_877da73c INTEGER;
  p_Configuration_877da73c TEXT;
  p_Status_877da73c VARCHAR(25);
  p_IsCustom_877da73c BOOLEAN;
  p_MetadataSource_877da73c VARCHAR(20);
BEGIN
  p_ID_877da73c := 'C1AAACBE-4215-4CD8-951A-A13FF8C00C8E';
  p_IntegrationObjectID_877da73c := '43358E6F-55C1-4D24-99B9-CCE3C79835FD';
  p_Name_877da73c := 'EventScope';
  p_DisplayName_877da73c := 'Event Scope';
  p_Description_877da73c := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_877da73c := 'Identity';
  p_Type_877da73c := 'TEXT';
  p_Length_877da73c := 100;
  p_AllowsNull_877da73c := FALSE;
  p_IsPrimaryKey_877da73c := TRUE;
  p_IsUniqueKey_877da73c := FALSE;
  p_IsReadOnly_877da73c := TRUE;
  p_IsRequired_877da73c := FALSE;
  p_Sequence_877da73c := 61;
  p_Configuration_877da73c := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_877da73c := 'Active';
  p_IsCustom_877da73c := FALSE;
  p_MetadataSource_877da73c := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_877da73c, p_IntegrationObjectID := p_IntegrationObjectID_877da73c, p_Name := p_Name_877da73c, p_DisplayName := p_DisplayName_877da73c, p_Description := p_Description_877da73c, p_Category := p_Category_877da73c, p_Type := p_Type_877da73c, p_Length := p_Length_877da73c, p_Precision := p_Precision_877da73c, p_Precision_Clear := TRUE, p_Scale := p_Scale_877da73c, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_877da73c, p_DefaultValue := p_DefaultValue_877da73c, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_877da73c, p_IsUniqueKey := p_IsUniqueKey_877da73c, p_IsReadOnly := p_IsReadOnly_877da73c, p_IsRequired := p_IsRequired_877da73c, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_877da73c, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_877da73c, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_877da73c, p_Configuration := p_Configuration_877da73c, p_Status := p_Status_877da73c, p_IsCustom := p_IsCustom_877da73c, p_MetadataSource := p_MetadataSource_877da73c);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_65cd3c43 UUID;
  p_IntegrationObjectID_65cd3c43 UUID;
  p_Name_65cd3c43 VARCHAR(255);
  p_DisplayName_65cd3c43 VARCHAR(255);
  p_Description_65cd3c43 TEXT;
  p_Category_65cd3c43 VARCHAR(100);
  p_Type_65cd3c43 VARCHAR(100);
  p_Length_65cd3c43 INTEGER;
  p_Precision_65cd3c43 INTEGER;
  p_Scale_65cd3c43 INTEGER;
  p_AllowsNull_65cd3c43 BOOLEAN;
  p_DefaultValue_65cd3c43 VARCHAR(255);
  p_IsPrimaryKey_65cd3c43 BOOLEAN;
  p_IsUniqueKey_65cd3c43 BOOLEAN;
  p_IsReadOnly_65cd3c43 BOOLEAN;
  p_IsRequired_65cd3c43 BOOLEAN;
  p_RelatedIntegrationObjectID_65cd3c43 UUID;
  p_RelatedIntegrationObjectFieldName_65cd3c43 VARCHAR(255);
  p_Sequence_65cd3c43 INTEGER;
  p_Configuration_65cd3c43 TEXT;
  p_Status_65cd3c43 VARCHAR(25);
  p_IsCustom_65cd3c43 BOOLEAN;
  p_MetadataSource_65cd3c43 VARCHAR(20);
BEGIN
  p_ID_65cd3c43 := '2F1D8C20-4300-4CBF-9E99-541945464BE2';
  p_IntegrationObjectID_65cd3c43 := 'AFE04BC5-FAE1-42F6-822E-90A414B2C568';
  p_Name_65cd3c43 := 'EventScope';
  p_DisplayName_65cd3c43 := 'Event Scope';
  p_Description_65cd3c43 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_65cd3c43 := 'Identity';
  p_Type_65cd3c43 := 'TEXT';
  p_Length_65cd3c43 := 100;
  p_AllowsNull_65cd3c43 := FALSE;
  p_IsPrimaryKey_65cd3c43 := TRUE;
  p_IsUniqueKey_65cd3c43 := FALSE;
  p_IsReadOnly_65cd3c43 := TRUE;
  p_IsRequired_65cd3c43 := FALSE;
  p_Sequence_65cd3c43 := 14;
  p_Configuration_65cd3c43 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_65cd3c43 := 'Active';
  p_IsCustom_65cd3c43 := FALSE;
  p_MetadataSource_65cd3c43 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_65cd3c43, p_IntegrationObjectID := p_IntegrationObjectID_65cd3c43, p_Name := p_Name_65cd3c43, p_DisplayName := p_DisplayName_65cd3c43, p_Description := p_Description_65cd3c43, p_Category := p_Category_65cd3c43, p_Type := p_Type_65cd3c43, p_Length := p_Length_65cd3c43, p_Precision := p_Precision_65cd3c43, p_Precision_Clear := TRUE, p_Scale := p_Scale_65cd3c43, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_65cd3c43, p_DefaultValue := p_DefaultValue_65cd3c43, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_65cd3c43, p_IsUniqueKey := p_IsUniqueKey_65cd3c43, p_IsReadOnly := p_IsReadOnly_65cd3c43, p_IsRequired := p_IsRequired_65cd3c43, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_65cd3c43, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_65cd3c43, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_65cd3c43, p_Configuration := p_Configuration_65cd3c43, p_Status := p_Status_65cd3c43, p_IsCustom := p_IsCustom_65cd3c43, p_MetadataSource := p_MetadataSource_65cd3c43);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_5f9159a9 UUID;
  p_IntegrationObjectID_5f9159a9 UUID;
  p_Name_5f9159a9 VARCHAR(255);
  p_DisplayName_5f9159a9 VARCHAR(255);
  p_Description_5f9159a9 TEXT;
  p_Category_5f9159a9 VARCHAR(100);
  p_Type_5f9159a9 VARCHAR(100);
  p_Length_5f9159a9 INTEGER;
  p_Precision_5f9159a9 INTEGER;
  p_Scale_5f9159a9 INTEGER;
  p_AllowsNull_5f9159a9 BOOLEAN;
  p_DefaultValue_5f9159a9 VARCHAR(255);
  p_IsPrimaryKey_5f9159a9 BOOLEAN;
  p_IsUniqueKey_5f9159a9 BOOLEAN;
  p_IsReadOnly_5f9159a9 BOOLEAN;
  p_IsRequired_5f9159a9 BOOLEAN;
  p_RelatedIntegrationObjectID_5f9159a9 UUID;
  p_RelatedIntegrationObjectFieldName_5f9159a9 VARCHAR(255);
  p_Sequence_5f9159a9 INTEGER;
  p_Configuration_5f9159a9 TEXT;
  p_Status_5f9159a9 VARCHAR(25);
  p_IsCustom_5f9159a9 BOOLEAN;
  p_MetadataSource_5f9159a9 VARCHAR(20);
BEGIN
  p_ID_5f9159a9 := 'AE8A0B39-84CA-4EB0-A8D7-5CD964621870';
  p_IntegrationObjectID_5f9159a9 := '06730837-4799-4309-8327-9C4CE283BD16';
  p_Name_5f9159a9 := 'EventScope';
  p_DisplayName_5f9159a9 := 'Event Scope';
  p_Description_5f9159a9 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_5f9159a9 := 'Identity';
  p_Type_5f9159a9 := 'TEXT';
  p_Length_5f9159a9 := 100;
  p_AllowsNull_5f9159a9 := FALSE;
  p_IsPrimaryKey_5f9159a9 := TRUE;
  p_IsUniqueKey_5f9159a9 := FALSE;
  p_IsReadOnly_5f9159a9 := TRUE;
  p_IsRequired_5f9159a9 := FALSE;
  p_Sequence_5f9159a9 := 50;
  p_Configuration_5f9159a9 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_5f9159a9 := 'Active';
  p_IsCustom_5f9159a9 := FALSE;
  p_MetadataSource_5f9159a9 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_5f9159a9, p_IntegrationObjectID := p_IntegrationObjectID_5f9159a9, p_Name := p_Name_5f9159a9, p_DisplayName := p_DisplayName_5f9159a9, p_Description := p_Description_5f9159a9, p_Category := p_Category_5f9159a9, p_Type := p_Type_5f9159a9, p_Length := p_Length_5f9159a9, p_Precision := p_Precision_5f9159a9, p_Precision_Clear := TRUE, p_Scale := p_Scale_5f9159a9, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_5f9159a9, p_DefaultValue := p_DefaultValue_5f9159a9, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_5f9159a9, p_IsUniqueKey := p_IsUniqueKey_5f9159a9, p_IsReadOnly := p_IsReadOnly_5f9159a9, p_IsRequired := p_IsRequired_5f9159a9, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_5f9159a9, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_5f9159a9, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_5f9159a9, p_Configuration := p_Configuration_5f9159a9, p_Status := p_Status_5f9159a9, p_IsCustom := p_IsCustom_5f9159a9, p_MetadataSource := p_MetadataSource_5f9159a9);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_e3c316e7 UUID;
  p_IntegrationObjectID_e3c316e7 UUID;
  p_Name_e3c316e7 VARCHAR(255);
  p_DisplayName_e3c316e7 VARCHAR(255);
  p_Description_e3c316e7 TEXT;
  p_Category_e3c316e7 VARCHAR(100);
  p_Type_e3c316e7 VARCHAR(100);
  p_Length_e3c316e7 INTEGER;
  p_Precision_e3c316e7 INTEGER;
  p_Scale_e3c316e7 INTEGER;
  p_AllowsNull_e3c316e7 BOOLEAN;
  p_DefaultValue_e3c316e7 VARCHAR(255);
  p_IsPrimaryKey_e3c316e7 BOOLEAN;
  p_IsUniqueKey_e3c316e7 BOOLEAN;
  p_IsReadOnly_e3c316e7 BOOLEAN;
  p_IsRequired_e3c316e7 BOOLEAN;
  p_RelatedIntegrationObjectID_e3c316e7 UUID;
  p_RelatedIntegrationObjectFieldName_e3c316e7 VARCHAR(255);
  p_Sequence_e3c316e7 INTEGER;
  p_Configuration_e3c316e7 TEXT;
  p_Status_e3c316e7 VARCHAR(25);
  p_IsCustom_e3c316e7 BOOLEAN;
  p_MetadataSource_e3c316e7 VARCHAR(20);
BEGIN
  p_ID_e3c316e7 := '0F99F63E-1695-4B35-A6A2-3EDF338D16DF';
  p_IntegrationObjectID_e3c316e7 := '916F3AC7-10B1-4C89-B686-09CC39130DA1';
  p_Name_e3c316e7 := 'EventScope';
  p_DisplayName_e3c316e7 := 'Event Scope';
  p_Description_e3c316e7 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_e3c316e7 := 'Identity';
  p_Type_e3c316e7 := 'TEXT';
  p_Length_e3c316e7 := 100;
  p_AllowsNull_e3c316e7 := FALSE;
  p_IsPrimaryKey_e3c316e7 := TRUE;
  p_IsUniqueKey_e3c316e7 := FALSE;
  p_IsReadOnly_e3c316e7 := TRUE;
  p_IsRequired_e3c316e7 := FALSE;
  p_Sequence_e3c316e7 := 3;
  p_Configuration_e3c316e7 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_e3c316e7 := 'Active';
  p_IsCustom_e3c316e7 := FALSE;
  p_MetadataSource_e3c316e7 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_e3c316e7, p_IntegrationObjectID := p_IntegrationObjectID_e3c316e7, p_Name := p_Name_e3c316e7, p_DisplayName := p_DisplayName_e3c316e7, p_Description := p_Description_e3c316e7, p_Category := p_Category_e3c316e7, p_Type := p_Type_e3c316e7, p_Length := p_Length_e3c316e7, p_Precision := p_Precision_e3c316e7, p_Precision_Clear := TRUE, p_Scale := p_Scale_e3c316e7, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_e3c316e7, p_DefaultValue := p_DefaultValue_e3c316e7, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_e3c316e7, p_IsUniqueKey := p_IsUniqueKey_e3c316e7, p_IsReadOnly := p_IsReadOnly_e3c316e7, p_IsRequired := p_IsRequired_e3c316e7, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_e3c316e7, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_e3c316e7, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_e3c316e7, p_Configuration := p_Configuration_e3c316e7, p_Status := p_Status_e3c316e7, p_IsCustom := p_IsCustom_e3c316e7, p_MetadataSource := p_MetadataSource_e3c316e7);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_101b095a UUID;
  p_IntegrationObjectID_101b095a UUID;
  p_Name_101b095a VARCHAR(255);
  p_DisplayName_101b095a VARCHAR(255);
  p_Description_101b095a TEXT;
  p_Category_101b095a VARCHAR(100);
  p_Type_101b095a VARCHAR(100);
  p_Length_101b095a INTEGER;
  p_Precision_101b095a INTEGER;
  p_Scale_101b095a INTEGER;
  p_AllowsNull_101b095a BOOLEAN;
  p_DefaultValue_101b095a VARCHAR(255);
  p_IsPrimaryKey_101b095a BOOLEAN;
  p_IsUniqueKey_101b095a BOOLEAN;
  p_IsReadOnly_101b095a BOOLEAN;
  p_IsRequired_101b095a BOOLEAN;
  p_RelatedIntegrationObjectID_101b095a UUID;
  p_RelatedIntegrationObjectFieldName_101b095a VARCHAR(255);
  p_Sequence_101b095a INTEGER;
  p_Configuration_101b095a TEXT;
  p_Status_101b095a VARCHAR(25);
  p_IsCustom_101b095a BOOLEAN;
  p_MetadataSource_101b095a VARCHAR(20);
BEGIN
  p_ID_101b095a := '38C5477F-0D1F-4265-BB8D-840F3EA7A845';
  p_IntegrationObjectID_101b095a := '03357576-7ECA-438C-BF11-781F7BDE0B5C';
  p_Name_101b095a := 'EventScope';
  p_DisplayName_101b095a := 'Event Scope';
  p_Description_101b095a := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_101b095a := 'Identity';
  p_Type_101b095a := 'TEXT';
  p_Length_101b095a := 100;
  p_AllowsNull_101b095a := FALSE;
  p_IsPrimaryKey_101b095a := TRUE;
  p_IsUniqueKey_101b095a := FALSE;
  p_IsReadOnly_101b095a := TRUE;
  p_IsRequired_101b095a := FALSE;
  p_Sequence_101b095a := 12;
  p_Configuration_101b095a := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_101b095a := 'Active';
  p_IsCustom_101b095a := FALSE;
  p_MetadataSource_101b095a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_101b095a, p_IntegrationObjectID := p_IntegrationObjectID_101b095a, p_Name := p_Name_101b095a, p_DisplayName := p_DisplayName_101b095a, p_Description := p_Description_101b095a, p_Category := p_Category_101b095a, p_Type := p_Type_101b095a, p_Length := p_Length_101b095a, p_Precision := p_Precision_101b095a, p_Precision_Clear := TRUE, p_Scale := p_Scale_101b095a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_101b095a, p_DefaultValue := p_DefaultValue_101b095a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_101b095a, p_IsUniqueKey := p_IsUniqueKey_101b095a, p_IsReadOnly := p_IsReadOnly_101b095a, p_IsRequired := p_IsRequired_101b095a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_101b095a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_101b095a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_101b095a, p_Configuration := p_Configuration_101b095a, p_Status := p_Status_101b095a, p_IsCustom := p_IsCustom_101b095a, p_MetadataSource := p_MetadataSource_101b095a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_ddbda8ac UUID;
  p_IntegrationObjectID_ddbda8ac UUID;
  p_Name_ddbda8ac VARCHAR(255);
  p_DisplayName_ddbda8ac VARCHAR(255);
  p_Description_ddbda8ac TEXT;
  p_Category_ddbda8ac VARCHAR(100);
  p_Type_ddbda8ac VARCHAR(100);
  p_Length_ddbda8ac INTEGER;
  p_Precision_ddbda8ac INTEGER;
  p_Scale_ddbda8ac INTEGER;
  p_AllowsNull_ddbda8ac BOOLEAN;
  p_DefaultValue_ddbda8ac VARCHAR(255);
  p_IsPrimaryKey_ddbda8ac BOOLEAN;
  p_IsUniqueKey_ddbda8ac BOOLEAN;
  p_IsReadOnly_ddbda8ac BOOLEAN;
  p_IsRequired_ddbda8ac BOOLEAN;
  p_RelatedIntegrationObjectID_ddbda8ac UUID;
  p_RelatedIntegrationObjectFieldName_ddbda8ac VARCHAR(255);
  p_Sequence_ddbda8ac INTEGER;
  p_Configuration_ddbda8ac TEXT;
  p_Status_ddbda8ac VARCHAR(25);
  p_IsCustom_ddbda8ac BOOLEAN;
  p_MetadataSource_ddbda8ac VARCHAR(20);
BEGIN
  p_ID_ddbda8ac := '04AE6C45-D9EE-4633-AC2D-C5A70F5C0740';
  p_IntegrationObjectID_ddbda8ac := 'C22F436E-5B95-4CCB-A8B5-413D34F212E6';
  p_Name_ddbda8ac := 'EventScope';
  p_DisplayName_ddbda8ac := 'Event Scope';
  p_Description_ddbda8ac := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_ddbda8ac := 'Identity';
  p_Type_ddbda8ac := 'TEXT';
  p_Length_ddbda8ac := 100;
  p_AllowsNull_ddbda8ac := FALSE;
  p_IsPrimaryKey_ddbda8ac := TRUE;
  p_IsUniqueKey_ddbda8ac := FALSE;
  p_IsReadOnly_ddbda8ac := TRUE;
  p_IsRequired_ddbda8ac := FALSE;
  p_Sequence_ddbda8ac := 58;
  p_Configuration_ddbda8ac := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_ddbda8ac := 'Active';
  p_IsCustom_ddbda8ac := FALSE;
  p_MetadataSource_ddbda8ac := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_ddbda8ac, p_IntegrationObjectID := p_IntegrationObjectID_ddbda8ac, p_Name := p_Name_ddbda8ac, p_DisplayName := p_DisplayName_ddbda8ac, p_Description := p_Description_ddbda8ac, p_Category := p_Category_ddbda8ac, p_Type := p_Type_ddbda8ac, p_Length := p_Length_ddbda8ac, p_Precision := p_Precision_ddbda8ac, p_Precision_Clear := TRUE, p_Scale := p_Scale_ddbda8ac, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_ddbda8ac, p_DefaultValue := p_DefaultValue_ddbda8ac, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_ddbda8ac, p_IsUniqueKey := p_IsUniqueKey_ddbda8ac, p_IsReadOnly := p_IsReadOnly_ddbda8ac, p_IsRequired := p_IsRequired_ddbda8ac, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_ddbda8ac, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_ddbda8ac, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_ddbda8ac, p_Configuration := p_Configuration_ddbda8ac, p_Status := p_Status_ddbda8ac, p_IsCustom := p_IsCustom_ddbda8ac, p_MetadataSource := p_MetadataSource_ddbda8ac);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_18ef1be4 UUID;
  p_IntegrationObjectID_18ef1be4 UUID;
  p_Name_18ef1be4 VARCHAR(255);
  p_DisplayName_18ef1be4 VARCHAR(255);
  p_Description_18ef1be4 TEXT;
  p_Category_18ef1be4 VARCHAR(100);
  p_Type_18ef1be4 VARCHAR(100);
  p_Length_18ef1be4 INTEGER;
  p_Precision_18ef1be4 INTEGER;
  p_Scale_18ef1be4 INTEGER;
  p_AllowsNull_18ef1be4 BOOLEAN;
  p_DefaultValue_18ef1be4 VARCHAR(255);
  p_IsPrimaryKey_18ef1be4 BOOLEAN;
  p_IsUniqueKey_18ef1be4 BOOLEAN;
  p_IsReadOnly_18ef1be4 BOOLEAN;
  p_IsRequired_18ef1be4 BOOLEAN;
  p_RelatedIntegrationObjectID_18ef1be4 UUID;
  p_RelatedIntegrationObjectFieldName_18ef1be4 VARCHAR(255);
  p_Sequence_18ef1be4 INTEGER;
  p_Configuration_18ef1be4 TEXT;
  p_Status_18ef1be4 VARCHAR(25);
  p_IsCustom_18ef1be4 BOOLEAN;
  p_MetadataSource_18ef1be4 VARCHAR(20);
BEGIN
  p_ID_18ef1be4 := 'B29FE39C-91A3-48C9-B88C-3F55563317B3';
  p_IntegrationObjectID_18ef1be4 := '8FF8DBC7-B78A-4836-8D8E-567C30170321';
  p_Name_18ef1be4 := 'EventScope';
  p_DisplayName_18ef1be4 := 'Event Scope';
  p_Description_18ef1be4 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_18ef1be4 := 'Identity';
  p_Type_18ef1be4 := 'TEXT';
  p_Length_18ef1be4 := 100;
  p_AllowsNull_18ef1be4 := FALSE;
  p_IsPrimaryKey_18ef1be4 := TRUE;
  p_IsUniqueKey_18ef1be4 := FALSE;
  p_IsReadOnly_18ef1be4 := TRUE;
  p_IsRequired_18ef1be4 := FALSE;
  p_Sequence_18ef1be4 := 40;
  p_Configuration_18ef1be4 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_18ef1be4 := 'Active';
  p_IsCustom_18ef1be4 := FALSE;
  p_MetadataSource_18ef1be4 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_18ef1be4, p_IntegrationObjectID := p_IntegrationObjectID_18ef1be4, p_Name := p_Name_18ef1be4, p_DisplayName := p_DisplayName_18ef1be4, p_Description := p_Description_18ef1be4, p_Category := p_Category_18ef1be4, p_Type := p_Type_18ef1be4, p_Length := p_Length_18ef1be4, p_Precision := p_Precision_18ef1be4, p_Precision_Clear := TRUE, p_Scale := p_Scale_18ef1be4, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_18ef1be4, p_DefaultValue := p_DefaultValue_18ef1be4, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_18ef1be4, p_IsUniqueKey := p_IsUniqueKey_18ef1be4, p_IsReadOnly := p_IsReadOnly_18ef1be4, p_IsRequired := p_IsRequired_18ef1be4, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_18ef1be4, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_18ef1be4, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_18ef1be4, p_Configuration := p_Configuration_18ef1be4, p_Status := p_Status_18ef1be4, p_IsCustom := p_IsCustom_18ef1be4, p_MetadataSource := p_MetadataSource_18ef1be4);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_c744cf90 UUID;
  p_IntegrationObjectID_c744cf90 UUID;
  p_Name_c744cf90 VARCHAR(255);
  p_DisplayName_c744cf90 VARCHAR(255);
  p_Description_c744cf90 TEXT;
  p_Category_c744cf90 VARCHAR(100);
  p_Type_c744cf90 VARCHAR(100);
  p_Length_c744cf90 INTEGER;
  p_Precision_c744cf90 INTEGER;
  p_Scale_c744cf90 INTEGER;
  p_AllowsNull_c744cf90 BOOLEAN;
  p_DefaultValue_c744cf90 VARCHAR(255);
  p_IsPrimaryKey_c744cf90 BOOLEAN;
  p_IsUniqueKey_c744cf90 BOOLEAN;
  p_IsReadOnly_c744cf90 BOOLEAN;
  p_IsRequired_c744cf90 BOOLEAN;
  p_RelatedIntegrationObjectID_c744cf90 UUID;
  p_RelatedIntegrationObjectFieldName_c744cf90 VARCHAR(255);
  p_Sequence_c744cf90 INTEGER;
  p_Configuration_c744cf90 TEXT;
  p_Status_c744cf90 VARCHAR(25);
  p_IsCustom_c744cf90 BOOLEAN;
  p_MetadataSource_c744cf90 VARCHAR(20);
BEGIN
  p_ID_c744cf90 := 'EAACFA3C-0E90-406D-B66F-4433C0F13F94';
  p_IntegrationObjectID_c744cf90 := '6353021A-F7AA-4BF9-B406-2620EBEB517D';
  p_Name_c744cf90 := 'EventScope';
  p_DisplayName_c744cf90 := 'Event Scope';
  p_Description_c744cf90 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_c744cf90 := 'Identity';
  p_Type_c744cf90 := 'TEXT';
  p_Length_c744cf90 := 100;
  p_AllowsNull_c744cf90 := FALSE;
  p_IsPrimaryKey_c744cf90 := TRUE;
  p_IsUniqueKey_c744cf90 := FALSE;
  p_IsReadOnly_c744cf90 := TRUE;
  p_IsRequired_c744cf90 := FALSE;
  p_Sequence_c744cf90 := 37;
  p_Configuration_c744cf90 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_c744cf90 := 'Active';
  p_IsCustom_c744cf90 := FALSE;
  p_MetadataSource_c744cf90 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_c744cf90, p_IntegrationObjectID := p_IntegrationObjectID_c744cf90, p_Name := p_Name_c744cf90, p_DisplayName := p_DisplayName_c744cf90, p_Description := p_Description_c744cf90, p_Category := p_Category_c744cf90, p_Type := p_Type_c744cf90, p_Length := p_Length_c744cf90, p_Precision := p_Precision_c744cf90, p_Precision_Clear := TRUE, p_Scale := p_Scale_c744cf90, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_c744cf90, p_DefaultValue := p_DefaultValue_c744cf90, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_c744cf90, p_IsUniqueKey := p_IsUniqueKey_c744cf90, p_IsReadOnly := p_IsReadOnly_c744cf90, p_IsRequired := p_IsRequired_c744cf90, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_c744cf90, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_c744cf90, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_c744cf90, p_Configuration := p_Configuration_c744cf90, p_Status := p_Status_c744cf90, p_IsCustom := p_IsCustom_c744cf90, p_MetadataSource := p_MetadataSource_c744cf90);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_ce295ae5 UUID;
  p_IntegrationObjectID_ce295ae5 UUID;
  p_Name_ce295ae5 VARCHAR(255);
  p_DisplayName_ce295ae5 VARCHAR(255);
  p_Description_ce295ae5 TEXT;
  p_Category_ce295ae5 VARCHAR(100);
  p_Type_ce295ae5 VARCHAR(100);
  p_Length_ce295ae5 INTEGER;
  p_Precision_ce295ae5 INTEGER;
  p_Scale_ce295ae5 INTEGER;
  p_AllowsNull_ce295ae5 BOOLEAN;
  p_DefaultValue_ce295ae5 VARCHAR(255);
  p_IsPrimaryKey_ce295ae5 BOOLEAN;
  p_IsUniqueKey_ce295ae5 BOOLEAN;
  p_IsReadOnly_ce295ae5 BOOLEAN;
  p_IsRequired_ce295ae5 BOOLEAN;
  p_RelatedIntegrationObjectID_ce295ae5 UUID;
  p_RelatedIntegrationObjectFieldName_ce295ae5 VARCHAR(255);
  p_Sequence_ce295ae5 INTEGER;
  p_Configuration_ce295ae5 TEXT;
  p_Status_ce295ae5 VARCHAR(25);
  p_IsCustom_ce295ae5 BOOLEAN;
  p_MetadataSource_ce295ae5 VARCHAR(20);
BEGIN
  p_ID_ce295ae5 := '9FC9C447-5406-46CF-B521-4FB1CBC7CF25';
  p_IntegrationObjectID_ce295ae5 := '1AEF00BF-D9ED-4801-907F-CA25A3BE9FF4';
  p_Name_ce295ae5 := 'EventScope';
  p_DisplayName_ce295ae5 := 'Event Scope';
  p_Description_ce295ae5 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_ce295ae5 := 'Identity';
  p_Type_ce295ae5 := 'TEXT';
  p_Length_ce295ae5 := 100;
  p_AllowsNull_ce295ae5 := FALSE;
  p_IsPrimaryKey_ce295ae5 := TRUE;
  p_IsUniqueKey_ce295ae5 := FALSE;
  p_IsReadOnly_ce295ae5 := TRUE;
  p_IsRequired_ce295ae5 := FALSE;
  p_Sequence_ce295ae5 := 7;
  p_Configuration_ce295ae5 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_ce295ae5 := 'Active';
  p_IsCustom_ce295ae5 := FALSE;
  p_MetadataSource_ce295ae5 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_ce295ae5, p_IntegrationObjectID := p_IntegrationObjectID_ce295ae5, p_Name := p_Name_ce295ae5, p_DisplayName := p_DisplayName_ce295ae5, p_Description := p_Description_ce295ae5, p_Category := p_Category_ce295ae5, p_Type := p_Type_ce295ae5, p_Length := p_Length_ce295ae5, p_Precision := p_Precision_ce295ae5, p_Precision_Clear := TRUE, p_Scale := p_Scale_ce295ae5, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_ce295ae5, p_DefaultValue := p_DefaultValue_ce295ae5, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_ce295ae5, p_IsUniqueKey := p_IsUniqueKey_ce295ae5, p_IsReadOnly := p_IsReadOnly_ce295ae5, p_IsRequired := p_IsRequired_ce295ae5, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_ce295ae5, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_ce295ae5, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_ce295ae5, p_Configuration := p_Configuration_ce295ae5, p_Status := p_Status_ce295ae5, p_IsCustom := p_IsCustom_ce295ae5, p_MetadataSource := p_MetadataSource_ce295ae5);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_b7f17f97 UUID;
  p_IntegrationObjectID_b7f17f97 UUID;
  p_Name_b7f17f97 VARCHAR(255);
  p_DisplayName_b7f17f97 VARCHAR(255);
  p_Description_b7f17f97 TEXT;
  p_Category_b7f17f97 VARCHAR(100);
  p_Type_b7f17f97 VARCHAR(100);
  p_Length_b7f17f97 INTEGER;
  p_Precision_b7f17f97 INTEGER;
  p_Scale_b7f17f97 INTEGER;
  p_AllowsNull_b7f17f97 BOOLEAN;
  p_DefaultValue_b7f17f97 VARCHAR(255);
  p_IsPrimaryKey_b7f17f97 BOOLEAN;
  p_IsUniqueKey_b7f17f97 BOOLEAN;
  p_IsReadOnly_b7f17f97 BOOLEAN;
  p_IsRequired_b7f17f97 BOOLEAN;
  p_RelatedIntegrationObjectID_b7f17f97 UUID;
  p_RelatedIntegrationObjectFieldName_b7f17f97 VARCHAR(255);
  p_Sequence_b7f17f97 INTEGER;
  p_Configuration_b7f17f97 TEXT;
  p_Status_b7f17f97 VARCHAR(25);
  p_IsCustom_b7f17f97 BOOLEAN;
  p_MetadataSource_b7f17f97 VARCHAR(20);
BEGIN
  p_ID_b7f17f97 := '5CFB84AC-A638-4860-BA5F-47EC837B278F';
  p_IntegrationObjectID_b7f17f97 := '3BA04441-803D-4322-8082-E8B6AD04A66B';
  p_Name_b7f17f97 := 'EventScope';
  p_DisplayName_b7f17f97 := 'Event Scope';
  p_Description_b7f17f97 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_b7f17f97 := 'Identity';
  p_Type_b7f17f97 := 'TEXT';
  p_Length_b7f17f97 := 100;
  p_AllowsNull_b7f17f97 := FALSE;
  p_IsPrimaryKey_b7f17f97 := TRUE;
  p_IsUniqueKey_b7f17f97 := FALSE;
  p_IsReadOnly_b7f17f97 := TRUE;
  p_IsRequired_b7f17f97 := FALSE;
  p_Sequence_b7f17f97 := 4;
  p_Configuration_b7f17f97 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_b7f17f97 := 'Active';
  p_IsCustom_b7f17f97 := FALSE;
  p_MetadataSource_b7f17f97 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_b7f17f97, p_IntegrationObjectID := p_IntegrationObjectID_b7f17f97, p_Name := p_Name_b7f17f97, p_DisplayName := p_DisplayName_b7f17f97, p_Description := p_Description_b7f17f97, p_Category := p_Category_b7f17f97, p_Type := p_Type_b7f17f97, p_Length := p_Length_b7f17f97, p_Precision := p_Precision_b7f17f97, p_Precision_Clear := TRUE, p_Scale := p_Scale_b7f17f97, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_b7f17f97, p_DefaultValue := p_DefaultValue_b7f17f97, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_b7f17f97, p_IsUniqueKey := p_IsUniqueKey_b7f17f97, p_IsReadOnly := p_IsReadOnly_b7f17f97, p_IsRequired := p_IsRequired_b7f17f97, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_b7f17f97, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_b7f17f97, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_b7f17f97, p_Configuration := p_Configuration_b7f17f97, p_Status := p_Status_b7f17f97, p_IsCustom := p_IsCustom_b7f17f97, p_MetadataSource := p_MetadataSource_b7f17f97);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_cd58aaea UUID;
  p_IntegrationObjectID_cd58aaea UUID;
  p_Name_cd58aaea VARCHAR(255);
  p_DisplayName_cd58aaea VARCHAR(255);
  p_Description_cd58aaea TEXT;
  p_Category_cd58aaea VARCHAR(100);
  p_Type_cd58aaea VARCHAR(100);
  p_Length_cd58aaea INTEGER;
  p_Precision_cd58aaea INTEGER;
  p_Scale_cd58aaea INTEGER;
  p_AllowsNull_cd58aaea BOOLEAN;
  p_DefaultValue_cd58aaea VARCHAR(255);
  p_IsPrimaryKey_cd58aaea BOOLEAN;
  p_IsUniqueKey_cd58aaea BOOLEAN;
  p_IsReadOnly_cd58aaea BOOLEAN;
  p_IsRequired_cd58aaea BOOLEAN;
  p_RelatedIntegrationObjectID_cd58aaea UUID;
  p_RelatedIntegrationObjectFieldName_cd58aaea VARCHAR(255);
  p_Sequence_cd58aaea INTEGER;
  p_Configuration_cd58aaea TEXT;
  p_Status_cd58aaea VARCHAR(25);
  p_IsCustom_cd58aaea BOOLEAN;
  p_MetadataSource_cd58aaea VARCHAR(20);
BEGIN
  p_ID_cd58aaea := 'B033CC98-1D0A-49BE-865A-8CB04F7B6D49';
  p_IntegrationObjectID_cd58aaea := 'BB9667F0-36BB-4519-97CE-71AE5BF5463B';
  p_Name_cd58aaea := 'EventScope';
  p_DisplayName_cd58aaea := 'Event Scope';
  p_Description_cd58aaea := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. This object declares no key, so its identity is a hash of the whole record, which includes this value.';
  p_Category_cd58aaea := 'Attribute';
  p_Type_cd58aaea := 'TEXT';
  p_Length_cd58aaea := 100;
  p_AllowsNull_cd58aaea := FALSE;
  p_IsPrimaryKey_cd58aaea := FALSE;
  p_IsUniqueKey_cd58aaea := FALSE;
  p_IsReadOnly_cd58aaea := TRUE;
  p_IsRequired_cd58aaea := FALSE;
  p_Sequence_cd58aaea := 5;
  p_Configuration_cd58aaea := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_cd58aaea := 'Active';
  p_IsCustom_cd58aaea := FALSE;
  p_MetadataSource_cd58aaea := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_cd58aaea, p_IntegrationObjectID := p_IntegrationObjectID_cd58aaea, p_Name := p_Name_cd58aaea, p_DisplayName := p_DisplayName_cd58aaea, p_Description := p_Description_cd58aaea, p_Category := p_Category_cd58aaea, p_Type := p_Type_cd58aaea, p_Length := p_Length_cd58aaea, p_Precision := p_Precision_cd58aaea, p_Precision_Clear := TRUE, p_Scale := p_Scale_cd58aaea, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_cd58aaea, p_DefaultValue := p_DefaultValue_cd58aaea, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_cd58aaea, p_IsUniqueKey := p_IsUniqueKey_cd58aaea, p_IsReadOnly := p_IsReadOnly_cd58aaea, p_IsRequired := p_IsRequired_cd58aaea, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_cd58aaea, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_cd58aaea, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_cd58aaea, p_Configuration := p_Configuration_cd58aaea, p_Status := p_Status_cd58aaea, p_IsCustom := p_IsCustom_cd58aaea, p_MetadataSource := p_MetadataSource_cd58aaea);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_4536977e UUID;
  p_IntegrationObjectID_4536977e UUID;
  p_Name_4536977e VARCHAR(255);
  p_DisplayName_4536977e VARCHAR(255);
  p_Description_4536977e TEXT;
  p_Category_4536977e VARCHAR(100);
  p_Type_4536977e VARCHAR(100);
  p_Length_4536977e INTEGER;
  p_Precision_4536977e INTEGER;
  p_Scale_4536977e INTEGER;
  p_AllowsNull_4536977e BOOLEAN;
  p_DefaultValue_4536977e VARCHAR(255);
  p_IsPrimaryKey_4536977e BOOLEAN;
  p_IsUniqueKey_4536977e BOOLEAN;
  p_IsReadOnly_4536977e BOOLEAN;
  p_IsRequired_4536977e BOOLEAN;
  p_RelatedIntegrationObjectID_4536977e UUID;
  p_RelatedIntegrationObjectFieldName_4536977e VARCHAR(255);
  p_Sequence_4536977e INTEGER;
  p_Configuration_4536977e TEXT;
  p_Status_4536977e VARCHAR(25);
  p_IsCustom_4536977e BOOLEAN;
  p_MetadataSource_4536977e VARCHAR(20);
BEGIN
  p_ID_4536977e := 'E9D0A6DC-09E5-4279-A997-A77AC171C0A3';
  p_IntegrationObjectID_4536977e := 'C66CF1AA-8317-4EE8-BE27-E2987748C566';
  p_Name_4536977e := 'EventScope';
  p_DisplayName_4536977e := 'Event Scope';
  p_Description_4536977e := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. This object declares no key, so its identity is a hash of the whole record, which includes this value.';
  p_Category_4536977e := 'Attribute';
  p_Type_4536977e := 'TEXT';
  p_Length_4536977e := 100;
  p_AllowsNull_4536977e := FALSE;
  p_IsPrimaryKey_4536977e := FALSE;
  p_IsUniqueKey_4536977e := FALSE;
  p_IsReadOnly_4536977e := TRUE;
  p_IsRequired_4536977e := FALSE;
  p_Sequence_4536977e := 2;
  p_Configuration_4536977e := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_4536977e := 'Active';
  p_IsCustom_4536977e := FALSE;
  p_MetadataSource_4536977e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_4536977e, p_IntegrationObjectID := p_IntegrationObjectID_4536977e, p_Name := p_Name_4536977e, p_DisplayName := p_DisplayName_4536977e, p_Description := p_Description_4536977e, p_Category := p_Category_4536977e, p_Type := p_Type_4536977e, p_Length := p_Length_4536977e, p_Precision := p_Precision_4536977e, p_Precision_Clear := TRUE, p_Scale := p_Scale_4536977e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_4536977e, p_DefaultValue := p_DefaultValue_4536977e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_4536977e, p_IsUniqueKey := p_IsUniqueKey_4536977e, p_IsReadOnly := p_IsReadOnly_4536977e, p_IsRequired := p_IsRequired_4536977e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_4536977e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_4536977e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_4536977e, p_Configuration := p_Configuration_4536977e, p_Status := p_Status_4536977e, p_IsCustom := p_IsCustom_4536977e, p_MetadataSource := p_MetadataSource_4536977e);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_447651d9 UUID;
  p_IntegrationObjectID_447651d9 UUID;
  p_Name_447651d9 VARCHAR(255);
  p_DisplayName_447651d9 VARCHAR(255);
  p_Description_447651d9 TEXT;
  p_Category_447651d9 VARCHAR(100);
  p_Type_447651d9 VARCHAR(100);
  p_Length_447651d9 INTEGER;
  p_Precision_447651d9 INTEGER;
  p_Scale_447651d9 INTEGER;
  p_AllowsNull_447651d9 BOOLEAN;
  p_DefaultValue_447651d9 VARCHAR(255);
  p_IsPrimaryKey_447651d9 BOOLEAN;
  p_IsUniqueKey_447651d9 BOOLEAN;
  p_IsReadOnly_447651d9 BOOLEAN;
  p_IsRequired_447651d9 BOOLEAN;
  p_RelatedIntegrationObjectID_447651d9 UUID;
  p_RelatedIntegrationObjectFieldName_447651d9 VARCHAR(255);
  p_Sequence_447651d9 INTEGER;
  p_Configuration_447651d9 TEXT;
  p_Status_447651d9 VARCHAR(25);
  p_IsCustom_447651d9 BOOLEAN;
  p_MetadataSource_447651d9 VARCHAR(20);
BEGIN
  p_ID_447651d9 := '4115FC24-54CC-4089-914D-49FB75FFD7AE';
  p_IntegrationObjectID_447651d9 := '4F04433A-E002-4250-8B5D-AD0B5C91DF0D';
  p_Name_447651d9 := 'EventScope';
  p_DisplayName_447651d9 := 'Event Scope';
  p_Description_447651d9 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_447651d9 := 'Identity';
  p_Type_447651d9 := 'TEXT';
  p_Length_447651d9 := 100;
  p_AllowsNull_447651d9 := FALSE;
  p_IsPrimaryKey_447651d9 := TRUE;
  p_IsUniqueKey_447651d9 := FALSE;
  p_IsReadOnly_447651d9 := TRUE;
  p_IsRequired_447651d9 := FALSE;
  p_Sequence_447651d9 := 12;
  p_Configuration_447651d9 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_447651d9 := 'Active';
  p_IsCustom_447651d9 := FALSE;
  p_MetadataSource_447651d9 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_447651d9, p_IntegrationObjectID := p_IntegrationObjectID_447651d9, p_Name := p_Name_447651d9, p_DisplayName := p_DisplayName_447651d9, p_Description := p_Description_447651d9, p_Category := p_Category_447651d9, p_Type := p_Type_447651d9, p_Length := p_Length_447651d9, p_Precision := p_Precision_447651d9, p_Precision_Clear := TRUE, p_Scale := p_Scale_447651d9, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_447651d9, p_DefaultValue := p_DefaultValue_447651d9, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_447651d9, p_IsUniqueKey := p_IsUniqueKey_447651d9, p_IsReadOnly := p_IsReadOnly_447651d9, p_IsRequired := p_IsRequired_447651d9, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_447651d9, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_447651d9, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_447651d9, p_Configuration := p_Configuration_447651d9, p_Status := p_Status_447651d9, p_IsCustom := p_IsCustom_447651d9, p_MetadataSource := p_MetadataSource_447651d9);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_ddd2623b UUID;
  p_IntegrationObjectID_ddd2623b UUID;
  p_Name_ddd2623b VARCHAR(255);
  p_DisplayName_ddd2623b VARCHAR(255);
  p_Description_ddd2623b TEXT;
  p_Category_ddd2623b VARCHAR(100);
  p_Type_ddd2623b VARCHAR(100);
  p_Length_ddd2623b INTEGER;
  p_Precision_ddd2623b INTEGER;
  p_Scale_ddd2623b INTEGER;
  p_AllowsNull_ddd2623b BOOLEAN;
  p_DefaultValue_ddd2623b VARCHAR(255);
  p_IsPrimaryKey_ddd2623b BOOLEAN;
  p_IsUniqueKey_ddd2623b BOOLEAN;
  p_IsReadOnly_ddd2623b BOOLEAN;
  p_IsRequired_ddd2623b BOOLEAN;
  p_RelatedIntegrationObjectID_ddd2623b UUID;
  p_RelatedIntegrationObjectFieldName_ddd2623b VARCHAR(255);
  p_Sequence_ddd2623b INTEGER;
  p_Configuration_ddd2623b TEXT;
  p_Status_ddd2623b VARCHAR(25);
  p_IsCustom_ddd2623b BOOLEAN;
  p_MetadataSource_ddd2623b VARCHAR(20);
BEGIN
  p_ID_ddd2623b := 'C3238A9A-94C7-42C6-8408-0DFBC5990311';
  p_IntegrationObjectID_ddd2623b := '6CCC8434-6A8B-402C-8543-D4F3B2A4618E';
  p_Name_ddd2623b := 'EventScope';
  p_DisplayName_ddd2623b := 'Event Scope';
  p_Description_ddd2623b := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. This object declares no key, so its identity is a hash of the whole record, which includes this value.';
  p_Category_ddd2623b := 'Attribute';
  p_Type_ddd2623b := 'TEXT';
  p_Length_ddd2623b := 100;
  p_AllowsNull_ddd2623b := FALSE;
  p_IsPrimaryKey_ddd2623b := FALSE;
  p_IsUniqueKey_ddd2623b := FALSE;
  p_IsReadOnly_ddd2623b := TRUE;
  p_IsRequired_ddd2623b := FALSE;
  p_Sequence_ddd2623b := 3;
  p_Configuration_ddd2623b := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_ddd2623b := 'Active';
  p_IsCustom_ddd2623b := FALSE;
  p_MetadataSource_ddd2623b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_ddd2623b, p_IntegrationObjectID := p_IntegrationObjectID_ddd2623b, p_Name := p_Name_ddd2623b, p_DisplayName := p_DisplayName_ddd2623b, p_Description := p_Description_ddd2623b, p_Category := p_Category_ddd2623b, p_Type := p_Type_ddd2623b, p_Length := p_Length_ddd2623b, p_Precision := p_Precision_ddd2623b, p_Precision_Clear := TRUE, p_Scale := p_Scale_ddd2623b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_ddd2623b, p_DefaultValue := p_DefaultValue_ddd2623b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_ddd2623b, p_IsUniqueKey := p_IsUniqueKey_ddd2623b, p_IsReadOnly := p_IsReadOnly_ddd2623b, p_IsRequired := p_IsRequired_ddd2623b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_ddd2623b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_ddd2623b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_ddd2623b, p_Configuration := p_Configuration_ddd2623b, p_Status := p_Status_ddd2623b, p_IsCustom := p_IsCustom_ddd2623b, p_MetadataSource := p_MetadataSource_ddd2623b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_ee6f192e UUID;
  p_IntegrationObjectID_ee6f192e UUID;
  p_Name_ee6f192e VARCHAR(255);
  p_DisplayName_ee6f192e VARCHAR(255);
  p_Description_ee6f192e TEXT;
  p_Category_ee6f192e VARCHAR(100);
  p_Type_ee6f192e VARCHAR(100);
  p_Length_ee6f192e INTEGER;
  p_Precision_ee6f192e INTEGER;
  p_Scale_ee6f192e INTEGER;
  p_AllowsNull_ee6f192e BOOLEAN;
  p_DefaultValue_ee6f192e VARCHAR(255);
  p_IsPrimaryKey_ee6f192e BOOLEAN;
  p_IsUniqueKey_ee6f192e BOOLEAN;
  p_IsReadOnly_ee6f192e BOOLEAN;
  p_IsRequired_ee6f192e BOOLEAN;
  p_RelatedIntegrationObjectID_ee6f192e UUID;
  p_RelatedIntegrationObjectFieldName_ee6f192e VARCHAR(255);
  p_Sequence_ee6f192e INTEGER;
  p_Configuration_ee6f192e TEXT;
  p_Status_ee6f192e VARCHAR(25);
  p_IsCustom_ee6f192e BOOLEAN;
  p_MetadataSource_ee6f192e VARCHAR(20);
BEGIN
  p_ID_ee6f192e := 'A6F79472-3242-4DAA-80B3-0C67A853CFED';
  p_IntegrationObjectID_ee6f192e := '223ADBC1-3C24-466F-BBAA-1AE56707D918';
  p_Name_ee6f192e := 'EventScope';
  p_DisplayName_ee6f192e := 'Event Scope';
  p_Description_ee6f192e := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_ee6f192e := 'Identity';
  p_Type_ee6f192e := 'TEXT';
  p_Length_ee6f192e := 100;
  p_AllowsNull_ee6f192e := FALSE;
  p_IsPrimaryKey_ee6f192e := TRUE;
  p_IsUniqueKey_ee6f192e := FALSE;
  p_IsReadOnly_ee6f192e := TRUE;
  p_IsRequired_ee6f192e := FALSE;
  p_Sequence_ee6f192e := 10;
  p_Configuration_ee6f192e := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_ee6f192e := 'Active';
  p_IsCustom_ee6f192e := FALSE;
  p_MetadataSource_ee6f192e := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_ee6f192e, p_IntegrationObjectID := p_IntegrationObjectID_ee6f192e, p_Name := p_Name_ee6f192e, p_DisplayName := p_DisplayName_ee6f192e, p_Description := p_Description_ee6f192e, p_Category := p_Category_ee6f192e, p_Type := p_Type_ee6f192e, p_Length := p_Length_ee6f192e, p_Precision := p_Precision_ee6f192e, p_Precision_Clear := TRUE, p_Scale := p_Scale_ee6f192e, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_ee6f192e, p_DefaultValue := p_DefaultValue_ee6f192e, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_ee6f192e, p_IsUniqueKey := p_IsUniqueKey_ee6f192e, p_IsReadOnly := p_IsReadOnly_ee6f192e, p_IsRequired := p_IsRequired_ee6f192e, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_ee6f192e, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_ee6f192e, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_ee6f192e, p_Configuration := p_Configuration_ee6f192e, p_Status := p_Status_ee6f192e, p_IsCustom := p_IsCustom_ee6f192e, p_MetadataSource := p_MetadataSource_ee6f192e);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_cdb617d9 UUID;
  p_IntegrationObjectID_cdb617d9 UUID;
  p_Name_cdb617d9 VARCHAR(255);
  p_DisplayName_cdb617d9 VARCHAR(255);
  p_Description_cdb617d9 TEXT;
  p_Category_cdb617d9 VARCHAR(100);
  p_Type_cdb617d9 VARCHAR(100);
  p_Length_cdb617d9 INTEGER;
  p_Precision_cdb617d9 INTEGER;
  p_Scale_cdb617d9 INTEGER;
  p_AllowsNull_cdb617d9 BOOLEAN;
  p_DefaultValue_cdb617d9 VARCHAR(255);
  p_IsPrimaryKey_cdb617d9 BOOLEAN;
  p_IsUniqueKey_cdb617d9 BOOLEAN;
  p_IsReadOnly_cdb617d9 BOOLEAN;
  p_IsRequired_cdb617d9 BOOLEAN;
  p_RelatedIntegrationObjectID_cdb617d9 UUID;
  p_RelatedIntegrationObjectFieldName_cdb617d9 VARCHAR(255);
  p_Sequence_cdb617d9 INTEGER;
  p_Configuration_cdb617d9 TEXT;
  p_Status_cdb617d9 VARCHAR(25);
  p_IsCustom_cdb617d9 BOOLEAN;
  p_MetadataSource_cdb617d9 VARCHAR(20);
BEGIN
  p_ID_cdb617d9 := '12B37D48-50F0-4ECE-A0D9-3A41EBF91716';
  p_IntegrationObjectID_cdb617d9 := '3B5A0CD3-AFBE-49F3-8C24-8E2603245AD5';
  p_Name_cdb617d9 := 'EventScope';
  p_DisplayName_cdb617d9 := 'Event Scope';
  p_Description_cdb617d9 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_cdb617d9 := 'Identity';
  p_Type_cdb617d9 := 'TEXT';
  p_Length_cdb617d9 := 100;
  p_AllowsNull_cdb617d9 := FALSE;
  p_IsPrimaryKey_cdb617d9 := TRUE;
  p_IsUniqueKey_cdb617d9 := FALSE;
  p_IsReadOnly_cdb617d9 := TRUE;
  p_IsRequired_cdb617d9 := FALSE;
  p_Sequence_cdb617d9 := 62;
  p_Configuration_cdb617d9 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_cdb617d9 := 'Active';
  p_IsCustom_cdb617d9 := FALSE;
  p_MetadataSource_cdb617d9 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_cdb617d9, p_IntegrationObjectID := p_IntegrationObjectID_cdb617d9, p_Name := p_Name_cdb617d9, p_DisplayName := p_DisplayName_cdb617d9, p_Description := p_Description_cdb617d9, p_Category := p_Category_cdb617d9, p_Type := p_Type_cdb617d9, p_Length := p_Length_cdb617d9, p_Precision := p_Precision_cdb617d9, p_Precision_Clear := TRUE, p_Scale := p_Scale_cdb617d9, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_cdb617d9, p_DefaultValue := p_DefaultValue_cdb617d9, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_cdb617d9, p_IsUniqueKey := p_IsUniqueKey_cdb617d9, p_IsReadOnly := p_IsReadOnly_cdb617d9, p_IsRequired := p_IsRequired_cdb617d9, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_cdb617d9, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_cdb617d9, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_cdb617d9, p_Configuration := p_Configuration_cdb617d9, p_Status := p_Status_cdb617d9, p_IsCustom := p_IsCustom_cdb617d9, p_MetadataSource := p_MetadataSource_cdb617d9);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_93b9c71b UUID;
  p_IntegrationObjectID_93b9c71b UUID;
  p_Name_93b9c71b VARCHAR(255);
  p_DisplayName_93b9c71b VARCHAR(255);
  p_Description_93b9c71b TEXT;
  p_Category_93b9c71b VARCHAR(100);
  p_Type_93b9c71b VARCHAR(100);
  p_Length_93b9c71b INTEGER;
  p_Precision_93b9c71b INTEGER;
  p_Scale_93b9c71b INTEGER;
  p_AllowsNull_93b9c71b BOOLEAN;
  p_DefaultValue_93b9c71b VARCHAR(255);
  p_IsPrimaryKey_93b9c71b BOOLEAN;
  p_IsUniqueKey_93b9c71b BOOLEAN;
  p_IsReadOnly_93b9c71b BOOLEAN;
  p_IsRequired_93b9c71b BOOLEAN;
  p_RelatedIntegrationObjectID_93b9c71b UUID;
  p_RelatedIntegrationObjectFieldName_93b9c71b VARCHAR(255);
  p_Sequence_93b9c71b INTEGER;
  p_Configuration_93b9c71b TEXT;
  p_Status_93b9c71b VARCHAR(25);
  p_IsCustom_93b9c71b BOOLEAN;
  p_MetadataSource_93b9c71b VARCHAR(20);
BEGIN
  p_ID_93b9c71b := '6407BE1D-0404-42B1-8A00-378174D01F0D';
  p_IntegrationObjectID_93b9c71b := 'BBC39A58-D20C-4ED3-A5FB-5F8243ED71B9';
  p_Name_93b9c71b := 'EventScope';
  p_DisplayName_93b9c71b := 'Event Scope';
  p_Description_93b9c71b := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. This object declares no key, so its identity is a hash of the whole record, which includes this value.';
  p_Category_93b9c71b := 'Attribute';
  p_Type_93b9c71b := 'TEXT';
  p_Length_93b9c71b := 100;
  p_AllowsNull_93b9c71b := FALSE;
  p_IsPrimaryKey_93b9c71b := FALSE;
  p_IsUniqueKey_93b9c71b := FALSE;
  p_IsReadOnly_93b9c71b := TRUE;
  p_IsRequired_93b9c71b := FALSE;
  p_Sequence_93b9c71b := 5;
  p_Configuration_93b9c71b := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_93b9c71b := 'Active';
  p_IsCustom_93b9c71b := FALSE;
  p_MetadataSource_93b9c71b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_93b9c71b, p_IntegrationObjectID := p_IntegrationObjectID_93b9c71b, p_Name := p_Name_93b9c71b, p_DisplayName := p_DisplayName_93b9c71b, p_Description := p_Description_93b9c71b, p_Category := p_Category_93b9c71b, p_Type := p_Type_93b9c71b, p_Length := p_Length_93b9c71b, p_Precision := p_Precision_93b9c71b, p_Precision_Clear := TRUE, p_Scale := p_Scale_93b9c71b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_93b9c71b, p_DefaultValue := p_DefaultValue_93b9c71b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_93b9c71b, p_IsUniqueKey := p_IsUniqueKey_93b9c71b, p_IsReadOnly := p_IsReadOnly_93b9c71b, p_IsRequired := p_IsRequired_93b9c71b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_93b9c71b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_93b9c71b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_93b9c71b, p_Configuration := p_Configuration_93b9c71b, p_Status := p_Status_93b9c71b, p_IsCustom := p_IsCustom_93b9c71b, p_MetadataSource := p_MetadataSource_93b9c71b);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_4b58b27a UUID;
  p_IntegrationObjectID_4b58b27a UUID;
  p_Name_4b58b27a VARCHAR(255);
  p_DisplayName_4b58b27a VARCHAR(255);
  p_Description_4b58b27a TEXT;
  p_Category_4b58b27a VARCHAR(100);
  p_Type_4b58b27a VARCHAR(100);
  p_Length_4b58b27a INTEGER;
  p_Precision_4b58b27a INTEGER;
  p_Scale_4b58b27a INTEGER;
  p_AllowsNull_4b58b27a BOOLEAN;
  p_DefaultValue_4b58b27a VARCHAR(255);
  p_IsPrimaryKey_4b58b27a BOOLEAN;
  p_IsUniqueKey_4b58b27a BOOLEAN;
  p_IsReadOnly_4b58b27a BOOLEAN;
  p_IsRequired_4b58b27a BOOLEAN;
  p_RelatedIntegrationObjectID_4b58b27a UUID;
  p_RelatedIntegrationObjectFieldName_4b58b27a VARCHAR(255);
  p_Sequence_4b58b27a INTEGER;
  p_Configuration_4b58b27a TEXT;
  p_Status_4b58b27a VARCHAR(25);
  p_IsCustom_4b58b27a BOOLEAN;
  p_MetadataSource_4b58b27a VARCHAR(20);
BEGIN
  p_ID_4b58b27a := '8A622AC3-974A-47F5-B0A2-3ADF28F16E63';
  p_IntegrationObjectID_4b58b27a := '06DC1C76-19F0-429A-977D-858A88685289';
  p_Name_4b58b27a := 'EventScope';
  p_DisplayName_4b58b27a := 'Event Scope';
  p_Description_4b58b27a := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. This object declares no key, so its identity is a hash of the whole record, which includes this value.';
  p_Category_4b58b27a := 'Attribute';
  p_Type_4b58b27a := 'TEXT';
  p_Length_4b58b27a := 100;
  p_AllowsNull_4b58b27a := FALSE;
  p_IsPrimaryKey_4b58b27a := FALSE;
  p_IsUniqueKey_4b58b27a := FALSE;
  p_IsReadOnly_4b58b27a := TRUE;
  p_IsRequired_4b58b27a := FALSE;
  p_Sequence_4b58b27a := 5;
  p_Configuration_4b58b27a := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_4b58b27a := 'Active';
  p_IsCustom_4b58b27a := FALSE;
  p_MetadataSource_4b58b27a := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_4b58b27a, p_IntegrationObjectID := p_IntegrationObjectID_4b58b27a, p_Name := p_Name_4b58b27a, p_DisplayName := p_DisplayName_4b58b27a, p_Description := p_Description_4b58b27a, p_Category := p_Category_4b58b27a, p_Type := p_Type_4b58b27a, p_Length := p_Length_4b58b27a, p_Precision := p_Precision_4b58b27a, p_Precision_Clear := TRUE, p_Scale := p_Scale_4b58b27a, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_4b58b27a, p_DefaultValue := p_DefaultValue_4b58b27a, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_4b58b27a, p_IsUniqueKey := p_IsUniqueKey_4b58b27a, p_IsReadOnly := p_IsReadOnly_4b58b27a, p_IsRequired := p_IsRequired_4b58b27a, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_4b58b27a, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_4b58b27a, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_4b58b27a, p_Configuration := p_Configuration_4b58b27a, p_Status := p_Status_4b58b27a, p_IsCustom := p_IsCustom_4b58b27a, p_MetadataSource := p_MetadataSource_4b58b27a);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_d4037dc9 UUID;
  p_IntegrationObjectID_d4037dc9 UUID;
  p_Name_d4037dc9 VARCHAR(255);
  p_DisplayName_d4037dc9 VARCHAR(255);
  p_Description_d4037dc9 TEXT;
  p_Category_d4037dc9 VARCHAR(100);
  p_Type_d4037dc9 VARCHAR(100);
  p_Length_d4037dc9 INTEGER;
  p_Precision_d4037dc9 INTEGER;
  p_Scale_d4037dc9 INTEGER;
  p_AllowsNull_d4037dc9 BOOLEAN;
  p_DefaultValue_d4037dc9 VARCHAR(255);
  p_IsPrimaryKey_d4037dc9 BOOLEAN;
  p_IsUniqueKey_d4037dc9 BOOLEAN;
  p_IsReadOnly_d4037dc9 BOOLEAN;
  p_IsRequired_d4037dc9 BOOLEAN;
  p_RelatedIntegrationObjectID_d4037dc9 UUID;
  p_RelatedIntegrationObjectFieldName_d4037dc9 VARCHAR(255);
  p_Sequence_d4037dc9 INTEGER;
  p_Configuration_d4037dc9 TEXT;
  p_Status_d4037dc9 VARCHAR(25);
  p_IsCustom_d4037dc9 BOOLEAN;
  p_MetadataSource_d4037dc9 VARCHAR(20);
BEGIN
  p_ID_d4037dc9 := 'CCDE7666-EA93-420F-84FD-91D9FB0C4E35';
  p_IntegrationObjectID_d4037dc9 := '45974C8B-B879-44D4-96F9-C38F78D0AC69';
  p_Name_d4037dc9 := 'EventScope';
  p_DisplayName_d4037dc9 := 'Event Scope';
  p_Description_d4037dc9 := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_d4037dc9 := 'Identity';
  p_Type_d4037dc9 := 'TEXT';
  p_Length_d4037dc9 := 100;
  p_AllowsNull_d4037dc9 := FALSE;
  p_IsPrimaryKey_d4037dc9 := TRUE;
  p_IsUniqueKey_d4037dc9 := FALSE;
  p_IsReadOnly_d4037dc9 := TRUE;
  p_IsRequired_d4037dc9 := FALSE;
  p_Sequence_d4037dc9 := 4;
  p_Configuration_d4037dc9 := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_d4037dc9 := 'Active';
  p_IsCustom_d4037dc9 := FALSE;
  p_MetadataSource_d4037dc9 := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_d4037dc9, p_IntegrationObjectID := p_IntegrationObjectID_d4037dc9, p_Name := p_Name_d4037dc9, p_DisplayName := p_DisplayName_d4037dc9, p_Description := p_Description_d4037dc9, p_Category := p_Category_d4037dc9, p_Type := p_Type_d4037dc9, p_Length := p_Length_d4037dc9, p_Precision := p_Precision_d4037dc9, p_Precision_Clear := TRUE, p_Scale := p_Scale_d4037dc9, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_d4037dc9, p_DefaultValue := p_DefaultValue_d4037dc9, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_d4037dc9, p_IsUniqueKey := p_IsUniqueKey_d4037dc9, p_IsReadOnly := p_IsReadOnly_d4037dc9, p_IsRequired := p_IsRequired_d4037dc9, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_d4037dc9, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_d4037dc9, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_d4037dc9, p_Configuration := p_Configuration_d4037dc9, p_Status := p_Status_d4037dc9, p_IsCustom := p_IsCustom_d4037dc9, p_MetadataSource := p_MetadataSource_d4037dc9);
END $mj$;

-- Save MJ: Integration Object Fields (core SP call only)
DO $mj$
DECLARE
  p_ID_be845e0b UUID;
  p_IntegrationObjectID_be845e0b UUID;
  p_Name_be845e0b VARCHAR(255);
  p_DisplayName_be845e0b VARCHAR(255);
  p_Description_be845e0b TEXT;
  p_Category_be845e0b VARCHAR(100);
  p_Type_be845e0b VARCHAR(100);
  p_Length_be845e0b INTEGER;
  p_Precision_be845e0b INTEGER;
  p_Scale_be845e0b INTEGER;
  p_AllowsNull_be845e0b BOOLEAN;
  p_DefaultValue_be845e0b VARCHAR(255);
  p_IsPrimaryKey_be845e0b BOOLEAN;
  p_IsUniqueKey_be845e0b BOOLEAN;
  p_IsReadOnly_be845e0b BOOLEAN;
  p_IsRequired_be845e0b BOOLEAN;
  p_RelatedIntegrationObjectID_be845e0b UUID;
  p_RelatedIntegrationObjectFieldName_be845e0b VARCHAR(255);
  p_Sequence_be845e0b INTEGER;
  p_Configuration_be845e0b TEXT;
  p_Status_be845e0b VARCHAR(25);
  p_IsCustom_be845e0b BOOLEAN;
  p_MetadataSource_be845e0b VARCHAR(20);
BEGIN
  p_ID_be845e0b := '50B33B1B-68F3-4669-8E22-17F72B636868';
  p_IntegrationObjectID_be845e0b := '0ACD467E-BE5C-43CF-994B-44C211B12C08';
  p_Name_be845e0b := 'EventScope';
  p_DisplayName_be845e0b := 'Event Scope';
  p_Description_be845e0b := 'The Cadmium event this record was read under, stamped by the connector on every record: the connection''s configured eID, or, when the connection sets no eID, the connection''s own ID. Part of the primary key, so the same Cadmium id read for two events is two rows, never one row the last sync overwrote.';
  p_Category_be845e0b := 'Identity';
  p_Type_be845e0b := 'TEXT';
  p_Length_be845e0b := 100;
  p_AllowsNull_be845e0b := FALSE;
  p_IsPrimaryKey_be845e0b := TRUE;
  p_IsUniqueKey_be845e0b := FALSE;
  p_IsReadOnly_be845e0b := TRUE;
  p_IsRequired_be845e0b := FALSE;
  p_Sequence_be845e0b := 4;
  p_Configuration_be845e0b := '{"connectorStamped":"event-scope","valueSource":"The connection''s eID (credential first, then Configuration; the names eID, eId, EID, eventID, EventID, eventId, event_id are accepted), else the connection''s CompanyIntegration ID. Never read from the vendor payload.","reason":"All connections of this connector write into the same tables, and rows are matched by primary key across the whole table. Without the event in the key, the same Cadmium id read for two events (or through two connections) collapses into one row that the last sync overwrote."}';
  p_Status_be845e0b := 'Active';
  p_IsCustom_be845e0b := FALSE;
  p_MetadataSource_be845e0b := 'Declared';
  PERFORM __mj."spCreateIntegrationObjectField"(p_ID := p_ID_be845e0b, p_IntegrationObjectID := p_IntegrationObjectID_be845e0b, p_Name := p_Name_be845e0b, p_DisplayName := p_DisplayName_be845e0b, p_Description := p_Description_be845e0b, p_Category := p_Category_be845e0b, p_Type := p_Type_be845e0b, p_Length := p_Length_be845e0b, p_Precision := p_Precision_be845e0b, p_Precision_Clear := TRUE, p_Scale := p_Scale_be845e0b, p_Scale_Clear := TRUE, p_AllowsNull := p_AllowsNull_be845e0b, p_DefaultValue := p_DefaultValue_be845e0b, p_DefaultValue_Clear := TRUE, p_IsPrimaryKey := p_IsPrimaryKey_be845e0b, p_IsUniqueKey := p_IsUniqueKey_be845e0b, p_IsReadOnly := p_IsReadOnly_be845e0b, p_IsRequired := p_IsRequired_be845e0b, p_RelatedIntegrationObjectID := p_RelatedIntegrationObjectID_be845e0b, p_RelatedIntegrationObjectID_Clear := TRUE, p_RelatedIntegrationObjectFieldName := p_RelatedIntegrationObjectFieldName_be845e0b, p_RelatedIntegrationObjectFieldName_Clear := TRUE, p_Sequence := p_Sequence_be845e0b, p_Configuration := p_Configuration_be845e0b, p_Status := p_Status_be845e0b, p_IsCustom := p_IsCustom_be845e0b, p_MetadataSource := p_MetadataSource_be845e0b);
END $mj$;
