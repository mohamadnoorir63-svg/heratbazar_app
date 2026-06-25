const router = require('express').Router();
const jwt = require('jsonwebtoken');
const db = require('../db');

function getBearerToken(req) {
  const header = req.headers.authorization || req.headers.Authorization || '';
  if (!header.startsWith('Bearer ')) return '';
  return header.slice(7).trim();
}

function getAdmin(req) {
  try {
    const token = getBearerToken(req);
    const secret = String(process.env.ADMIN_JWT_SECRET || '');
    if (!token || !secret) return null;

    const payload = jwt.verify(token, secret);
    if (payload && payload.role === 'owner') return payload;

    return null;
  } catch (_) {
    return null;
  }
}

async function isBanned(userId, phone) {
  const result = await db.query(
    `
    SELECT id FROM official_group_bans
    WHERE user_id = $1 OR phone = $2
    LIMIT 1
    `,
    [userId || null, phone || null]
  );

  return result.rows.length > 0;
}

router.get('/messages', async (req, res) => {
  try {
    const result = await db.query(
      `
      SELECT
        m.*,
        u.first_name,
        u.last_name,
        u.role,
        u.is_verified,
        u.avatar_url
      FROM official_group_messages m
      LEFT JOIN users u ON u.id = m.sender_user_id
      ORDER BY m.is_pinned DESC, m.created_at DESC
      LIMIT 300
      `
    );

    res.json({
      success: true,
      messages: result.rows.reverse()
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/messages', async (req, res) => {
  try {
    const userId = req.body.user_id;
    const phone = req.body.phone;
    const message = String(req.body.message || '').trim();

    if (!userId || !phone || !message) {
      return res.status(400).json({
        success: false,
        error: 'user_id, phone and message required'
      });
    }

    const banned = await isBanned(userId, phone);

    if (banned) {
      return res.status(403).json({
        success: false,
        error: 'شما از گروه رسمی مسدود شده‌اید'
      });
    }

    const result = await db.query(
      `
      INSERT INTO official_group_messages(sender_user_id, sender_phone, message)
      VALUES($1, $2, $3)
      RETURNING *
      `,
      [userId, phone, message]
    );

    res.json({
      success: true,
      message: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.delete('/messages/:id', async (req, res) => {
  try {
    const admin = getAdmin(req);

    if (!admin) {
      return res.status(403).json({
        success: false,
        error: 'admin token required'
      });
    }

    const messageId = req.params.id;

    const result = await db.query(
      'DELETE FROM official_group_messages WHERE id = $1 RETURNING id',
      [messageId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'message not found'
      });
    }

    res.json({
      success: true,
      deleted_id: result.rows[0].id
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.patch('/messages/:id/pin', async (req, res) => {
  try {
    const admin = getAdmin(req);

    if (!admin) {
      return res.status(403).json({
        success: false,
        error: 'admin token required'
      });
    }

    const messageId = req.params.id;

    await db.query(
      'UPDATE official_group_messages SET is_pinned = false WHERE is_pinned = true'
    );

    const result = await db.query(
      `
      UPDATE official_group_messages
      SET is_pinned = true,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
      `,
      [messageId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'message not found'
      });
    }

    res.json({
      success: true,
      message: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.patch('/messages/:id/unpin', async (req, res) => {
  try {
    const admin = getAdmin(req);

    if (!admin) {
      return res.status(403).json({
        success: false,
        error: 'admin token required'
      });
    }

    const messageId = req.params.id;

    const result = await db.query(
      `
      UPDATE official_group_messages
      SET is_pinned = false,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
      `,
      [messageId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'message not found'
      });
    }

    res.json({
      success: true,
      message: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/ban', async (req, res) => {
  try {
    const admin = getAdmin(req);

    if (!admin) {
      return res.status(403).json({
        success: false,
        error: 'admin token required'
      });
    }

    const userId = req.body.user_id || null;
    const phone = req.body.phone || null;
    const reason = req.body.reason || 'مسدود شده توسط مدیریت';

    if (!userId && !phone) {
      return res.status(400).json({
        success: false,
        error: 'user_id or phone required'
      });
    }

    const result = await db.query(
      `
      INSERT INTO official_group_bans(user_id, phone, reason)
      VALUES($1, $2, $3)
      ON CONFLICT (user_id)
      DO UPDATE SET
        phone = EXCLUDED.phone,
        reason = EXCLUDED.reason,
        banned_at = CURRENT_TIMESTAMP
      RETURNING *
      `,
      [userId, phone, reason]
    );

    res.json({
      success: true,
      ban: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/unban', async (req, res) => {
  try {
    const admin = getAdmin(req);

    if (!admin) {
      return res.status(403).json({
        success: false,
        error: 'admin token required'
      });
    }

    const userId = req.body.user_id || null;
    const phone = req.body.phone || null;

    if (!userId && !phone) {
      return res.status(400).json({
        success: false,
        error: 'user_id or phone required'
      });
    }

    const result = await db.query(
      `
      DELETE FROM official_group_bans
      WHERE user_id = $1 OR phone = $2
      RETURNING *
      `,
      [userId, phone]
    );

    res.json({
      success: true,
      removed: result.rows
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
