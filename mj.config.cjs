// mj.config.cjs — DB connection for seed-migration GENERATION only (mj sync push / codegen).
// NOT shipped to customers; the published artifact is each connector's migrations/ + dist/.
// Generation target is a 5.43 baseline DB (e.g. MJ_CONN_CLEAN on the sql-claude container).
// All values come from env so no credentials are committed.
module.exports = {
  dbHost: process.env.DB_HOST || 'localhost',
  dbPort: process.env.DB_PORT ? parseInt(process.env.DB_PORT, 10) : 1433,
  dbDatabase: process.env.DB_DATABASE,
  dbUsername: process.env.DB_USERNAME,
  dbPassword: process.env.DB_PASSWORD,
  dbTrustServerCertificate: 'Y',
  mjCoreSchema: '__mj',

  // Per-request SQL timeout for the seed push. mssql defaults to 15s, which is fine for a small
  // catalog and NOT fine for a large one: SFMC (225 objects / 3,786 fields) aborts partway through
  // MJ: Integration Object Fields with `Timeout: Request failed to complete in 15000ms`, rolls the
  // whole transaction back, and emits a truncated migration. The failure looks like a data problem
  // and is purely a clock. 15 minutes is generous enough for the largest catalogs we ship.
  dbRequestTimeout: process.env.MJ_MIGRATION_REQUEST_TIMEOUT
    ? parseInt(process.env.MJ_MIGRATION_REQUEST_TIMEOUT, 10)
    : 900000,

  // mj sync push reads the metadata directory tree; each connector pushes its own metadata/ folder.
  // The sqlLogging block in each connector's metadata/.mj-sync.json emits the seed SQL into migrations/.
};
