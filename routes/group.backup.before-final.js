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

async function touchMember(userId, phone) {
  if (!userId) return;

  await db.query(
    `
    INSERT INTO official_group_members(user_id, phone)
    VALUES($1, $2)
    ON CONFLICT(user_id)
    DO UPDATE SET
      phone = EXCLUDED.phone,
      last_seen = CURRENT_TIMESTAMP
    `,
    [userId, phone || null]
  );
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

router.get('/stats', async (req, res) => {
  try {
    const members = await db.query(
      'SELECT COUNT(*)::int AS count FROM official_group_members'
    );

    const messages = await db.query(
      'SELECT COUNT(*)::int AS count FROM official_group_messages'
    );

    const pinned = await db.query(
      'SELECT COUNT(*)::int AS count FROM official_group_messages WHERE is_pinned = true'
    );

    res.json({
      success: true,
      stats: {
        members: members.rows[0].count,
        messages: messages.rows[0].count,
        pinned_messages: pinned.rows[0].count
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.get('/messages', async (req, res) => {
  try {
    const q = String(req.query.q || '').trim();
    const limit = Math.min(parseInt(req.query.limit || '300', 10), 500);

    const result = await db.query(
      `
      SELECT
        m.*,
        u.first_name,
        u.last_name,
        u.role,
        u.is_verified,
        u.avatar_url,
        r.message AS reply_message,
        ru.first_name AS reply_first_name,
        ru.last_name AS reply_last_name
      FROM official_group_messages m
      LEFT JOIN users u ON u.id = m.sender_user_id
      LEFT JOIN official_group_messages r ON r.id = m.reply_to_message_id
      LEFT JOIN users ru ON ru.id = r.sender_user_id
      WHERE ($1 = '' OR m.message ILIKE '%' || $1 || '%')
      ORDER BY m.is_pinned DESC, m.created_at DESC
      LIMIT $2
      `,
      [q, limit]
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

    const messageType = req.body.message_type || 'text';
    const mediaUrl = req.body.media_url || null;
    const mediaName = req.body.media_name || null;
    const mediaMime = req.body.media_mime || null;
    const replyToMessageId = req.body.reply_to_message_id || null;

    if (!userId || !phone) {
      return res.status(400).json({
        success: false,
        error: 'user_id and phone required'
      });
    }

    if (!message && !mediaUrl) {
      return res.status(400).json({
        success: false,
        error: 'message or media_url required'
      });
    }

    const banned = await isBanned(userId, phone);

    if (banned) {
      return res.status(403).json({
        success: false,
        error: 'شما از گروه رسمی مسدود شده‌اید'
      });
    }

    await touchMember(userId, phone);

    const result = await db.query(
      `
      INSERT INTO official_group_messages(
        sender_user_id,
        sender_phone,
        message,
        message_type,
        media_url,
        media_name,
        media_mime,
        reply_to_message_id
      )
      VALUES($1,$2,$3,$4,$5,$6,$7,$8)
      RETURNING *
      `,
      [
        userId,
        phone,
        message,
        messageType,
        mediaUrl,
        mediaName,
        mediaMime,
        replyToMessageId
      ]
    );

    res.json({
      success: true,
      message: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/messages/:id/react', async (req, res) => {
  try {
    const messageId = req.params.id;
    const userId = req.body.user_id;
    const reaction = req.body.reaction || 'like';

    if (!userId) {
      return res.status(400).json({
        success: false,
        error: 'user_id required'
      });
    }

    const exists = await db.query(
      `
      SELECT id FROM official_group_reactions
      WHERE message_id = $1 AND user_id = $2 AND reaction = $3
      `,
      [messageId, userId, reaction]
    );

    if (exists.rows.length > 0) {
      await db.query(
        'DELETE FROM official_group_reactions WHERE id = $1',
        [exists.rows[0].id]
      );
    } else {
      await db.query(
        `
        INSERT INTO official_group_reactions(message_id, user_id, reaction)
        VALUES($1,$2,$3)
        `,
        [messageId, userId, reaction]
      );
    }

    const count = await db.query(
      `
      SELECT COUNT(*)::int AS count
      FROM official_group_reactions
      WHERE message_id = $1 AND reaction = 'like'
      `,
      [messageId]
    );

    const updated = await db.query(
      `
      UPDATE official_group_messages
      SET like_count = $1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING id, like_count
      `,
      [count.rows[0].count, messageId]
    );

    res.json({
      success: true,
      message: updated.rows[0],
      reacted: exists.rows.length === 0
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

    const result = await db.query(
      'DELETE FROM official_group_messages WHERE id = $1 RETURNING id',
      [req.params.id]
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
      [req.params.id]
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

    const result = await db.query(
      `
      UPDATE official_group_messages
      SET is_pinned = false,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
      `,
      [req.params.id]
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

    await db.query(
      `
      DELETE FROM official_group_bans
      WHERE user_id = $1 OR phone = $2
      `,
      [userId, phone]
    );

    const result = await db.query(
      `
      INSERT INTO official_group_bans(user_id, phone, reason)
      VALUES($1,$2,$3)
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
