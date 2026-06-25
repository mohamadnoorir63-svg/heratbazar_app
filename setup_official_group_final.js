require('dotenv').config();
const db = require('./db');

async function main() {
  try {
    await db.query(`
      ALTER TABLE official_group_messages
      ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;
    `);

    await db.query(`
      ALTER TABLE official_group_messages
      ADD COLUMN IF NOT EXISTS edited_at TIMESTAMP;
    `);

    await db.query(`
      ALTER TABLE official_group_members
      ADD COLUMN IF NOT EXISTS is_typing BOOLEAN DEFAULT false;
    `);

    await db.query(`
      ALTER TABLE official_group_members
      ADD COLUMN IF NOT EXISTS unread_count INTEGER DEFAULT 0;
    `);

    await db.query(`
      ALTER TABLE official_group_members
      ADD COLUMN IF NOT EXISTS muted_until TIMESTAMP;
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS official_group_admin_logs (
        id SERIAL PRIMARY KEY,
        admin_user_id INTEGER,
        admin_phone VARCHAR(50),
        action VARCHAR(100) NOT NULL,
        target_user_id INTEGER,
        target_phone VARCHAR(50),
        message_id INTEGER,
        details TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await db.query(`
      CREATE TABLE IF NOT EXISTS official_group_announcements (
        id SERIAL PRIMARY KEY,
        title VARCHAR(200) NOT NULL,
        body TEXT NOT NULL,
        is_active BOOLEAN DEFAULT true,
        created_by VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    console.log('Official group final setup completed.');
    process.exit(0);
  } catch (err) {
    console.error('Setup failed:', err.message);
    process.exit(1);
  }
}

main();
