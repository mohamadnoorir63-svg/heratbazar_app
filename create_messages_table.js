require('dotenv').config();
const db = require('./db');

async function main() {
  await db.query(`
    CREATE TABLE IF NOT EXISTS messages (
      id SERIAL PRIMARY KEY,
      ad_id INTEGER NOT NULL,
      sender_phone VARCHAR(30) NOT NULL,
      message TEXT NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  `);

  console.log('messages table created');
  process.exit(0);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
