const router = require('express').Router();
const bcrypt = require('bcryptjs');
const db = require('../db');

function generateCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function normalizePhone(phone) {
  let p = String(phone || '').trim();
  p = p.replace(/\s+/g, '');
  p = p.replace(/-/g, '');

  if (p.startsWith('0093')) p = '+93' + p.slice(4);
  if (p.startsWith('93')) p = '+93' + p.slice(2);
  if (p.startsWith('07')) p = '+93' + p.slice(1);

  return p;
}

router.post('/register', async (req, res) => {
  try {
    const {
      first_name,
      last_name,
      phone,
      security_question,
      security_answer
    } = req.body;

    if (!first_name || !last_name || !phone || !security_answer) {
      return res.status(400).json({ error: 'همه فیلدها لازم است' });
    }

    const cleanPhone = normalizePhone(phone);

    const exists = await db.query(
      'SELECT id FROM users WHERE phone=$1',
      [cleanPhone]
    );

    if (exists.rows.length > 0) {
      return res.status(400).json({
        error: 'شماره قبلاً ثبت شده است'
      });
    }

    const loginCode = generateCode();
    const codeHash = await bcrypt.hash(loginCode, 10);
    const answerHash = await bcrypt.hash(
      String(security_answer).trim().toLowerCase(),
      10
    );

    const result = await db.query(
      `
      INSERT INTO users(
        first_name,
        last_name,
        phone,
        login_code_hash,
        security_question,
        security_answer_hash
      )
      VALUES($1,$2,$3,$4,$5,$6)
      RETURNING id, first_name, last_name, phone, security_question
      `,
      [
        first_name.trim(),
        last_name.trim(),
        cleanPhone,
        codeHash,
        security_question || 'نام اولین معلم شما چیست؟',
        answerHash
      ]
    );

    res.json({
      success: true,
      user: result.rows[0],
      login_code: loginCode,
      message: 'ثبت‌نام موفق شد. این کد ورود را نگه دارید.'
    });

  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { phone, login_code } = req.body;

    if (!phone || !login_code) {
      return res.status(400).json({ error: 'شماره و کد ورود لازم است' });
    }

    const cleanPhone = normalizePhone(phone);

    const result = await db.query(
      'SELECT * FROM users WHERE phone=$1 AND is_active=true',
      [cleanPhone]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'کاربر پیدا نشد' });
    }

    const user = result.rows[0];

    const ok = await bcrypt.compare(
      String(login_code).trim(),
      user.login_code_hash
    );

    if (!ok) {
      return res.status(401).json({ error: 'کد ورود اشتباه است' });
    }

    res.json({
      success: true,
      user: {
        id: user.id,
        first_name: user.first_name,
        last_name: user.last_name,
        phone: user.phone,
        security_question: user.security_question
      }
    });

  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/forgot-code', async (req, res) => {
  try {
    const {
      first_name,
      last_name,
      phone,
      security_answer
    } = req.body;

    if (!first_name || !last_name || !phone || !security_answer) {
      return res.status(400).json({ error: 'همه فیلدها لازم است' });
    }

    const cleanPhone = normalizePhone(phone);

    const result = await db.query(
      'SELECT * FROM users WHERE phone=$1 AND is_active=true',
      [cleanPhone]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'کاربر پیدا نشد' });
    }

    const user = result.rows[0];

    if (
      user.first_name.trim() !== first_name.trim() ||
      user.last_name.trim() !== last_name.trim()
    ) {
      return res.status(401).json({ error: 'نام یا نام خانوادگی اشتباه است' });
    }

    const answerOk = await bcrypt.compare(
      String(security_answer).trim().toLowerCase(),
      user.security_answer_hash
    );

    if (!answerOk) {
      return res.status(401).json({ error: 'جواب سوال امنیتی اشتباه است' });
    }

    const newCode = generateCode();
    const newHash = await bcrypt.hash(newCode, 10);

    await db.query(
      `
      UPDATE users
      SET login_code_hash=$1,
          updated_at=NOW()
      WHERE id=$2
      `,
      [newHash, user.id]
    );

    res.json({
      success: true,
      new_code: newCode,
      message: 'کد جدید ساخته شد. آن را نگه دارید.'
    });

  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
