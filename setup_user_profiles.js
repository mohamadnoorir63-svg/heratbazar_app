require('dotenv').config();
const db = require('./db');

async function main() {
  try {
    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS avatar_url TEXT;
    `);

    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS bio TEXT;
    `);

    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS city VARCHAR(100);
    `);

    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
    `);

    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS rating NUMERIC(3,2) DEFAULT 5.00;
    `);

    await db.query(`
      ALTER TABLE users
      ADD COLUMN IF NOT EXISTS rating_count INTEGER DEFAULT 0;
    `);

    console.log("User profile setup completed.");
    process.exit(0);

  } catch(err){
    console.error(err.message);
    process.exit(1);
  }
}

main();
