require('dotenv').config();
const db = require('./db');

async function main() {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS official_group_messages (
        id SERIAL PRIMARY KEY,
        sender_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        sender_phone VARCHAR(50),
        message TEXT NOT NULL,
        is_pinned BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS official_group_bans (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        phone VARCHAR(50),
        reason TEXT,
        banned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id)
      );
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_official_group_messages_created
      ON official_group_messages(created_at DESC);
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_official_group_messages_pinned
      ON official_group_messages(is_pinned, created_at DESC);
    `);

    console.log('Official group setup completed.');
    process.exit(0);
  } catch (err) {
    console.error('Setup failed:', err.message);
    process.exit(1);
  }
}

main();
