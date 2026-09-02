-- Delta for metadata/integration/.elevate.integration.json: two declared objects gain their
-- incremental watermark fields, which also gives windowed (date-sliced) reads a field to slice
-- on — the vendor 500s unbounded full-table reports on large resources.
--   EarnedCredit        -> updated_at      (present in its declared field set)
--   ProductRegistration -> transaction_at  (modified_at filters to zero rows on the wire; the
--                                           29,003-row capability proof was cut on transaction_at slices)
UPDATE [__mj].[IntegrationObject] SET [IncrementalWatermarkField] = 'updated_at'
 WHERE [ID] = '8C74F301-4FBD-4E8A-ABAD-472081B16666';
UPDATE [__mj].[IntegrationObject] SET [IncrementalWatermarkField] = 'transaction_at'
 WHERE [ID] = '0C640A45-DB60-458C-8A18-ADDF26120B02';
