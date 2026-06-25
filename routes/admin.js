const router = require('express').Router();
const jwt = require('jsonwebtoken');
const db = require('../db');

function getBearerToken(req) {
  const header = req.headers.authorization || req.headers.Authorization || '';
  if (!header.startsWith('Bearer ')) return '';
  return header.slice(7).trim();
}

function requireAdmin(req, res, next) {
  try {
    const token = getBearerToken(req);
    const secret = String(process.env.ADMIN_JWT_SECRET || '');

    if (!token || !secret) {
      return res.status(403).json({
        success: false,
        error: 'admin token required'
      });
    }

    const payload = jwt.verify(token, secret);

    if (!payload || payload.role !== 'owner') {
      return res.status(403).json({
        success: false,
        error: 'not allowed'
      });
    }

    req.admin = payload;
    next();
  } catch (_) {
    return res.status(403).json({
      success: false,
      error: 'invalid admin token'
    });
  }
}

router.get('/stats', requireAdmin, async (req, res) => {
  try {
    const users = await db.query('SELECT COUNT(*)::int AS count FROM users');
    const ads = await db.query('SELECT COUNT(*)::int AS count FROM ads');
    const messages = await db.query('SELECT COUNT(*)::int AS count FROM messages');
    const bannedUsers = await db.query(
      'SELECT COUNT(*)::int AS count FROM users WHERE is_banned = true'
    );
    const pinnedAds = await db.query(
      'SELECT COUNT(*)::int AS count FROM ads WHERE is_pinned = true'
    );

    res.json({
      success: true,
      stats: {
        users: users.rows[0].count,
        ads: ads.rows[0].count,
        messages: messages.rows[0].count,
        banned_users: bannedUsers.rows[0].count,
        pinned_ads: pinnedAds.rows[0].count
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.get('/users', requireAdmin, async (req, res) => {
  try {
    const result = await db.query(`
      SELECT
        id,
        first_name,
        last_name,
        phone,
        role,
        is_verified,
        is_banned,
        banned_at,
        ban_reason,
        created_at,
        updated_at
      FROM users
      ORDER BY id DESC
      LIMIT 500
    `);

    res.json({
      success: true,
      users: result.rows
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.patch('/users/:id/ban', requireAdmin, async (req, res) => {
  try {
    const userId = req.params.id;
    const reason = req.body.reason || 'مسدود شده توسط مدیریت';

    const result = await db.query(
      `
      UPDATE users
      SET is_banned = true,
          banned_at = CURRENT_TIMESTAMP,
          ban_reason = $1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING id, first_name, last_name, phone, role, is_verified, is_banned, banned_at, ban_reason
      `,
      [reason, userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'user not found'
      });
    }

    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.patch('/users/:id/unban', requireAdmin, async (req, res) => {
  try {
    const userId = req.params.id;

    const result = await db.query(
      `
      UPDATE users
      SET is_banned = false,
          banned_at = NULL,
          ban_reason = NULL,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING id, first_name, last_name, phone, role, is_verified, is_banned, banned_at, ban_reason
      `,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'user not found'
      });
    }

    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.patch('/users/:id/verify', requireAdmin, async (req, res) => {
  try {
    const userId = req.params.id;

    const result = await db.query(
      `
      UPDATE users
      SET is_verified = true,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING id, first_name, last_name, phone, role, is_verified, is_banned
      `,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'user not found'
      });
    }

    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.patch('/users/:id/unverify', requireAdmin, async (req, res) => {
  try {
    const userId = req.params.id;

    const result = await db.query(
      `
      UPDATE users
      SET is_verified = false,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING id, first_name, last_name, phone, role, is_verified, is_banned
      `,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'user not found'
      });
    }

    res.json({
      success: true,
      user: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
