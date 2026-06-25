const express = require('express');
const db = require('../db');

const router = express.Router();

router.post('/send', async (req, res) => {
  try {
    const { ad_id, sender_phone, receiver_phone, message } = req.body;

    if (!ad_id || !sender_phone || !receiver_phone || !message) {
      return res.status(400).json({
        success: false,
        error: 'ad_id, sender_phone, receiver_phone and message required'
      });
    }

    const result = await db.query(
      `INSERT INTO messages (ad_id, sender_phone, receiver_phone, message)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [
        ad_id,
        sender_phone.trim(),
        receiver_phone.trim(),
        message.trim()
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

router.get('/messages/:adId', async (req, res) => {
  try {
    const adId = req.params.adId;
    const myPhone = (req.query.my_phone || '').trim();
    const otherPhone = (req.query.other_phone || '').trim();

    if (!myPhone || !otherPhone) {
      return res.status(400).json({
        success: false,
        error: 'my_phone and other_phone required'
      });
    }

    const result = await db.query(
      `SELECT *
       FROM messages
       WHERE ad_id = $1
       AND (
         (sender_phone = $2 AND receiver_phone = $3)
         OR
         (sender_phone = $3 AND receiver_phone = $2)
       )
       ORDER BY created_at ASC`,
      [adId, myPhone, otherPhone]
    );

    res.json({
      success: true,
      messages: result.rows
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.get('/conversations', async (req, res) => {
  try {
    const myPhone = (req.query.my_phone || '').trim();

    if (!myPhone) {
      return res.status(400).json({
        success: false,
        error: 'my_phone required'
      });
    }

    const result = await db.query(
      `SELECT DISTINCT ON (m.ad_id,
        CASE
          WHEN m.sender_phone = $1 THEN m.receiver_phone
          ELSE m.sender_phone
        END
      )
        m.ad_id,
        a.title AS ad_title,
        a.image_url,
        CASE
          WHEN m.sender_phone = $1 THEN m.receiver_phone
          ELSE m.sender_phone
        END AS other_phone,
        m.message AS last_message,
        m.created_at AS last_time
       FROM messages m
       LEFT JOIN ads a ON a.id = m.ad_id
       WHERE m.sender_phone = $1 OR m.receiver_phone = $1
       ORDER BY
        m.ad_id,
        CASE
          WHEN m.sender_phone = $1 THEN m.receiver_phone
          ELSE m.sender_phone
        END,
        m.created_at DESC`,
      [myPhone]
    );

    res.json({
      success: true,
      conversations: result.rows
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
