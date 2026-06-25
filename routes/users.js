const router = require('express').Router();
const db = require('../db');

router.get('/:id/profile', async (req, res) => {
  try {
    const userId = req.params.id;

    const userResult = await db.query(
      `
      SELECT
        id,
        first_name,
        last_name,
        phone,
        role,
        is_verified,
        avatar_url,
        bio,
        city,
        rating,
        rating_count,
        created_at,
        last_seen
      FROM users
      WHERE id = $1 AND is_active = true
      `,
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'user not found'
      });
    }

    const adsResult = await db.query(
      `
      SELECT
        ads.*,
        categories.name AS category_name,
        COALESCE(
          json_agg(ad_images.image_url ORDER BY ad_images.id)
          FILTER (WHERE ad_images.image_url IS NOT NULL),
          '[]'
        ) AS images
      FROM ads
      LEFT JOIN categories ON categories.id = ads.category_id
      LEFT JOIN ad_images ON ad_images.ad_id = ads.id
      WHERE ads.user_id = $1
      GROUP BY ads.id, categories.name
      ORDER BY
        ads.is_pinned DESC,
        ads.pinned_at DESC NULLS LAST,
        ads.id DESC
      `,
      [userId]
    );

    res.json({
      success: true,
      user: userResult.rows[0],
      ads_count: adsResult.rows.length,
      ads: adsResult.rows
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.put('/:id/profile', async (req, res) => {
  try {
    const userId = req.params.id;
    const requestUserId = req.body.user_id;

    if (!requestUserId || Number(requestUserId) !== Number(userId)) {
      return res.status(403).json({
        success: false,
        error: 'not allowed'
      });
    }

    const {
      first_name,
      last_name,
      avatar_url,
      bio,
      city
    } = req.body;

    const result = await db.query(
      `
      UPDATE users
      SET first_name = COALESCE($1, first_name),
          last_name = COALESCE($2, last_name),
          avatar_url = COALESCE($3, avatar_url),
          bio = COALESCE($4, bio),
          city = COALESCE($5, city),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $6
      RETURNING
        id,
        first_name,
        last_name,
        phone,
        role,
        is_verified,
        avatar_url,
        bio,
        city,
        rating,
        rating_count,
        created_at,
        last_seen
      `,
      [
        first_name ?? null,
        last_name ?? null,
        avatar_url ?? null,
        bio ?? null,
        city ?? null,
        userId
      ]
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

router.post('/:id/last-seen', async (req, res) => {
  try {
    const userId = req.params.id;

    const result = await db.query(
      `
      UPDATE users
      SET last_seen = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING id, last_seen
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
      user_id: result.rows[0].id,
      last_seen: result.rows[0].last_seen
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
