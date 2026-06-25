require('dotenv').config();
const db = require('./db');

async function main() {
  try {
    await db.query(`
      ALTER TABLE ads
      ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT false;
    `);

    await db.query(`
      ALTER TABLE ads
      ADD COLUMN IF NOT EXISTS pinned_at TIMESTAMP;
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_ads_pinned
      ON ads(is_pinned, pinned_at DESC);
    `);

    console.log('Admin ads columns ready.');
    process.exit(0);
  } catch (err) {
    console.error('Setup failed:', err.message);
    process.exit(1);
  }
}

main();
