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

  // mj sync push reads the metadata directory tree; each connector pushes its own metadata/ folder.
  // The sqlLogging block in each connector's metadata/.mj-sync.json emits the seed SQL into migrations/.
};
