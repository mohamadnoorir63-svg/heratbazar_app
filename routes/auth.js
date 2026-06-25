const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');

function generateCode() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

function normalizePhone(phone) {
  let p = String(phone || '').trim();
  p = p.replace(/\s+/g, '');
  p = p.replace(/-/g, '');

  if (p.startsWith('+')) {
    p = p.slice(1);
  }

  return p;
}

function validatePhone(phone) {
  const cleanPhone = normalizePhone(phone);

  if (!/^0\d{10,11}$/.test(cleanPhone)) {
    return {
      ok: false,
      phone: cleanPhone,
      error: 'شماره تماس باید با 0 شروع شود و 11 یا 12 رقم باشد'
    };
  }

  return {
    ok: true,
    phone: cleanPhone
  };
}

function publicUser(user) {
  return {
    id: user.id,
    first_name: user.first_name,
    last_name: user.last_name,
    phone: user.phone,
    security_question: user.security_question,
    role: user.role || 'user',
    is_verified: user.is_verified === true,
    is_banned: user.is_banned === true
  };
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

    const phoneCheck = validatePhone(phone);
    if (!phoneCheck.ok) {
      return res.status(400).json({ error: phoneCheck.error });
    }

    const cleanPhone = phoneCheck.phone;

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
        security_answer_hash,
        role,
        is_verified,
        is_banned
      )
      VALUES($1,$2,$3,$4,$5,$6,'user',false,false)
      RETURNING id, first_name, last_name, phone, security_question, role, is_verified, is_banned
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

    const phoneCheck = validatePhone(phone);
    if (!phoneCheck.ok) {
      return res.status(400).json({ error: phoneCheck.error });
    }

    const cleanPhone = phoneCheck.phone;

    const result = await db.query(
      'SELECT * FROM users WHERE phone=$1 AND is_active=true',
      [cleanPhone]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'کاربر پیدا نشد' });
    }

    const user = result.rows[0];

    if (user.is_banned === true) {
      return res.status(403).json({ error: 'حساب شما مسدود شده است' });
    }

    const ok = await bcrypt.compare(
      String(login_code).trim(),
      user.login_code_hash
    );

    if (!ok) {
      return res.status(401).json({ error: 'کد ورود اشتباه است' });
    }

    const isOwnerPhone =
      cleanPhone === normalizePhone(process.env.OWNER_PHONE);

    res.json({
      success: true,
      is_owner_phone: isOwnerPhone,
      user: publicUser(user)
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

router.post('/admin-verify', async (req, res) => {
  try {
    const {
      phone,
      email,
      birthday,
      admin_password
    } = req.body;

    if (!phone || !email || !birthday || !admin_password) {
      return res.status(400).json({
        success: false,
        error: 'شماره، ایمیل، تاریخ تولد و رمز مدیر لازم است'
      });
    }

    const phoneCheck = validatePhone(phone);
    if (!phoneCheck.ok) {
      return res.status(400).json({ success: false, error: phoneCheck.error });
    }

    const cleanPhone = phoneCheck.phone;

    const ownerPhone = normalizePhone(process.env.OWNER_PHONE);
    const ownerEmail = String(process.env.OWNER_EMAIL || '').trim().toLowerCase();
    const ownerBirthday = String(process.env.OWNER_BIRTHDAY || '').trim();
    const adminPassword = String(process.env.ADMIN_PASSWORD || '');
    const jwtSecret = String(process.env.ADMIN_JWT_SECRET || '');

    if (!ownerPhone || !ownerEmail || !ownerBirthday || !adminPassword || !jwtSecret) {
      return res.status(500).json({
        success: false,
        error: 'تنظیمات ادمین در سرور کامل نیست'
      });
    }

    const ok =
      cleanPhone === ownerPhone &&
      String(email).trim().toLowerCase() === ownerEmail &&
      String(birthday).trim() === ownerBirthday &&
      String(admin_password) === adminPassword;

    if (!ok) {
      return res.status(401).json({
        success: false,
        error: 'اطلاعات مدیر درست نیست'
      });
    }

    const userResult = await db.query(
      'SELECT * FROM users WHERE phone=$1 AND is_active=true',
      [cleanPhone]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'حساب مدیر در جدول کاربران پیدا نشد'
      });
    }

    const user = userResult.rows[0];

    await db.query(
      `
      UPDATE users
      SET role='owner',
          is_verified=true,
          is_banned=false,
          updated_at=NOW()
      WHERE id=$1
      `,
      [user.id]
    );

    const token = jwt.sign(
      {
        user_id: user.id,
        phone: cleanPhone,
        role: 'owner'
      },
      jwtSecret,
      {
        expiresIn: '30d'
      }
    );

    res.json({
      success: true,
      admin_token: token,
      user: {
        ...publicUser(user),
        role: 'owner',
        is_verified: true,
        is_banned: false
      }
    });
  } catch (e) {
    res.status(500).json({ success: false, error: e.message });
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

    const phoneCheck = validatePhone(phone);
    if (!phoneCheck.ok) {
      return res.status(400).json({ error: phoneCheck.error });
    }

    const cleanPhone = phoneCheck.phone;

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
