require('dotenv').config();
const db = require('./db');

async function main() {
  try {
    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'user';
    `);

    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false;
    `);

    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS is_banned BOOLEAN DEFAULT false;
    `);

    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS banned_at TIMESTAMP;
    `);

    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS ban_reason TEXT;
    `);

    console.log('Admin features setup completed.');
    process.exit(0);
  } catch (err) {
    console.error('Setup failed:', err.message);
    process.exit(1);
  }
}

main();
