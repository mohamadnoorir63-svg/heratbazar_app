require('dotenv').config();
const db = require('./db');

async function main() {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS user_devices (
        id SERIAL PRIMARY KEY,
        phone VARCHAR(50) NOT NULL,
        fcm_token TEXT NOT NULL UNIQUE,
        platform VARCHAR(20),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    await db.query(`
      ALTER TABLE messages
      ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT false;
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_user_devices_phone
      ON user_devices(phone);
    `);

    await db.query(`
      CREATE INDEX IF NOT EXISTS idx_messages_receiver_read
      ON messages(receiver_phone, is_read);
    `);

    console.log('Notifications setup completed successfully.');
    process.exit(0);
  } catch (err) {
    console.error('Setup failed:', err.message);
    process.exit(1);
  }
}

main();
