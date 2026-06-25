require('dotenv').config();
const db = require('./db');

async function main() {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS ad_reports (
        id SERIAL PRIMARY KEY,
        ad_id INTEGER NOT NULL REFERENCES ads(id) ON DELETE CASCADE,
        reporter_phone VARCHAR(50),
        reason TEXT NOT NULL,
        status VARCHAR(20) DEFAULT 'pending',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        reviewed_at TIMESTAMP,
        reviewed_by VARCHAR(50)
      );
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_ad_reports_ad_id
      ON ad_reports(ad_id);
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_ad_reports_status
      ON ad_reports(status);
    `);

    console.log('Reports setup completed.');
    process.exit(0);
  } catch (err) {
    console.error('Setup failed:', err.message);
    process.exit(1);
  }
}

main();
