require('dotenv').config();
const db = require('./db');

async function main() {
  try {
    await db.query(`
      ALTER TABLE official_group_messages
      ADD COLUMN IF NOT EXISTS message_type VARCHAR(20) DEFAULT 'text';
    `);

    await db.query(`
      ALTER TABLE official_group_messages
      ADD COLUMN IF NOT EXISTS media_url TEXT;
    `);

    await db.query(`
      ALTER TABLE official_group_messages
      ADD COLUMN IF NOT EXISTS media_name TEXT;
    `);

    await db.query(`
      ALTER TABLE official_group_messages
      ADD COLUMN IF NOT EXISTS media_mime TEXT;
    `);

    await db.query(`
      ALTER TABLE official_group_messages
      ADD COLUMN IF NOT EXISTS reply_to_message_id INTEGER REFERENCES official_group_messages(id) ON DELETE SET NULL;
    `);

    await db.query(`
      ALTER TABLE official_group_messages
      ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0;
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS official_group_reactions (
        id SERIAL PRIMARY KEY,
        message_id INTEGER NOT NULL REFERENCES official_group_messages(id) ON DELETE CASCADE,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        reaction VARCHAR(20) DEFAULT 'like',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(message_id, user_id, reaction)
      );
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS official_group_members (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        phone VARCHAR(50),
        joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id)
      );
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_official_group_messages_search
      ON official_group_messages USING gin(to_tsvector('simple', message));
    `);

    console.log('Official group plus setup completed.');
    process.exit(0);
  } catch (err) {
    console.error('Setup failed:', err.message);
    process.exit(1);
  }
}

main();
