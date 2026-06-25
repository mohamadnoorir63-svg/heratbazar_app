require('dotenv').config();
const db = require('./db');

async function main() {
  try {
    await db.query(`
      ALTER TABLE ads
      ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;
    `);

    await db.query(`
      ALTER TABLE ads
      ADD COLUMN IF NOT EXISTS favorite_count INTEGER DEFAULT 0;
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_ads_view_count
      ON ads(view_count DESC);
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_ads_favorite_count
      ON ads(favorite_count DESC);
    `);

    console.log('Ad stats setup completed.');
    process.exit(0);
  } catch (err) {
    console.error('Setup failed:', err.message);
    process.exit(1);
  }
}

main();
