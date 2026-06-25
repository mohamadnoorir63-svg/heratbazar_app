const router = require('express').Router();
const jwt = require('jsonwebtoken');
const db = require('../db');

function getBearerToken(req) {
  const header = req.headers.authorization || req.headers.Authorization || '';
  if (!header.startsWith('Bearer ')) return '';
  return header.slice(7).trim();
}

function verifyAdmin(req) {
  try {
    const token = getBearerToken(req);
    if (!token) return null;

    const secret = String(process.env.ADMIN_JWT_SECRET || '');
    if (!secret) return null;

    const payload = jwt.verify(token, secret);

    if (payload && payload.role === 'owner') {
      return payload;
    }

    return null;
  } catch (_) {
    return null;
  }
}

router.get('/', async (req, res) => {
  try {
    const result = await db.query(`
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
      GROUP BY ads.id, categories.name
      ORDER BY
        ads.is_pinned DESC,
        ads.pinned_at DESC NULLS LAST,
        ads.id DESC
    `);

    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const {
      title,
      description,
      price,
      phone,
      city,
      province,
      district,
      category_id,
      image_url,
      images,
      owner_token,
      user_id
    } = req.body;

    if (!user_id) {
      return res.status(400).json({ error: 'user_id required' });
    }

    const result = await db.query(`
      INSERT INTO ads (
        title,
        description,
        price,
        phone,
        city,
        province,
        district,
        category_id,
        image_url,
        owner_token,
        user_id
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
      RETURNING *
    `, [
      title || '',
      description || '',
      price || 0,
      phone || '',
      city || province || 'Herat',
      province || null,
      district || null,
      category_id || null,
      image_url || null,
      owner_token || null,
      user_id || null
    ]);

    const ad = result.rows[0];
    const imageList = Array.isArray(images) ? images.slice(0, 20) : [];

    if (image_url && imageList.length === 0) {
      imageList.push(image_url);
    }

    for (const url of imageList) {
      if (!url) continue;

      await db.query(
        'INSERT INTO ad_images (ad_id, image_url) VALUES ($1, $2)',
        [ad.id, url]
      );
    }

    ad.images = imageList;
    res.json(ad);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const adId = req.params.id;

    const {
      title,
      description,
      price,
      phone,
      city,
      province,
      district,
      category_id,
      image_url,
      images,
      user_id
    } = req.body;

    if (!user_id) {
      return res.status(400).json({ error: 'user_id required' });
    }

    const check = await db.query(
      'SELECT * FROM ads WHERE id = $1',
      [adId]
    );

    if (check.rows.length === 0) {
      return res.status(404).json({ error: 'ad not found' });
    }

    const oldAd = check.rows[0];

    const userOk =
      user_id &&
      oldAd.user_id &&
      Number(oldAd.user_id) === Number(user_id);

    if (!userOk) {
      return res.status(403).json({ error: 'not allowed' });
    }

    const result = await db.query(`
      UPDATE ads SET
        title = $1,
        description = $2,
        price = $3,
        phone = $4,
        city = $5,
        province = $6,
        district = $7,
        category_id = $8,
        image_url = $9,
        user_id = COALESCE($10, user_id),
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $11
      RETURNING *
    `, [
      title || '',
      description || '',
      price || 0,
      phone || '',
      city || province || 'Herat',
      province || null,
      district || null,
      category_id || null,
      image_url || null,
      user_id || null,
      adId
    ]);

    const ad = result.rows[0];

    if (Array.isArray(images)) {
      const imageList = images.slice(0, 20);

      await db.query('DELETE FROM ad_images WHERE ad_id = $1', [adId]);

      for (const url of imageList) {
        if (!url) continue;

        await db.query(
          'INSERT INTO ad_images (ad_id, image_url) VALUES ($1, $2)',
          [ad.id, url]
        );
      }

      ad.images = imageList;
    }

    res.json(ad);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.patch('/:id/pin', async (req, res) => {
  try {
    const admin = verifyAdmin(req);

    if (!admin) {
      return res.status(403).json({
        success: false,
        error: 'admin token required'
      });
    }

    const adId = req.params.id;

    const result = await db.query(
      `
      UPDATE ads
      SET is_pinned = true,
          pinned_at = CURRENT_TIMESTAMP,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
      `,
      [adId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'ad not found'
      });
    }

    res.json({
      success: true,
      ad: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.patch('/:id/unpin', async (req, res) => {
  try {
    const admin = verifyAdmin(req);

    if (!admin) {
      return res.status(403).json({
        success: false,
        error: 'admin token required'
      });
    }

    const adId = req.params.id;

    const result = await db.query(
      `
      UPDATE ads
      SET is_pinned = false,
          pinned_at = NULL,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING *
      `,
      [adId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'ad not found'
      });
    }

    res.json({
      success: true,
      ad: result.rows[0]
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const adId = req.params.id;
    const admin = verifyAdmin(req);

    const user_id = req.body.user_id || req.query.user_id;

    const check = await db.query(
      'SELECT * FROM ads WHERE id = $1',
      [adId]
    );

    if (check.rows.length === 0) {
      return res.status(404).json({ error: 'ad not found' });
    }

    const ad = check.rows[0];

    const userOk =
      user_id &&
      ad.user_id &&
      Number(ad.user_id) === Number(user_id);

    if (!admin && !userOk) {
      return res.status(403).json({ error: 'not allowed' });
    }

    await db.query('DELETE FROM ad_images WHERE ad_id = $1', [adId]);
    await db.query('DELETE FROM ads WHERE id = $1', [adId]);

    res.json({
      ok: true,
      success: true,
      deleted_id: adId,
      deleted_by: admin ? 'admin' : 'owner'
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});



router.post('/:id/report', async (req, res) => {
  try {
    const adId = req.params.id;
    const reporterPhone = req.body.reporter_phone || req.query.reporter_phone || null;
    const reason = String(req.body.reason || '').trim();

    if (!reason) {
      return res.status(400).json({
        success: false,
        error: 'reason required'
      });
    }

    const adCheck = await db.query(
      'SELECT id FROM ads WHERE id = $1',
      [adId]
    );

    if (adCheck.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'ad not found'
      });
    }

    const result = await db.query(
      `
      INSERT INTO ad_reports(ad_id, reporter_phone, reason)
      VALUES($1, $2, $3)
      RETURNING *
      `,
      [adId, reporterPhone, reason]
    );

    res.json({
      success: true,
      report: result.rows[0],
      message: 'گزارش شما ثبت شد'
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});



router.post('/:id/view', async (req, res) => {
  try {
    const adId = req.params.id;

    const result = await db.query(
      `
      UPDATE ads
      SET view_count = COALESCE(view_count, 0) + 1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING id, view_count
      `,
      [adId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'ad not found'
      });
    }

    res.json({
      success: true,
      ad_id: result.rows[0].id,
      view_count: result.rows[0].view_count
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/:id/favorite/increment', async (req, res) => {
  try {
    const adId = req.params.id;

    const result = await db.query(
      `
      UPDATE ads
      SET favorite_count = COALESCE(favorite_count, 0) + 1,
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING id, favorite_count
      `,
      [adId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'ad not found'
      });
    }

    res.json({
      success: true,
      ad_id: result.rows[0].id,
      favorite_count: result.rows[0].favorite_count
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

router.post('/:id/favorite/decrement', async (req, res) => {
  try {
    const adId = req.params.id;

    const result = await db.query(
      `
      UPDATE ads
      SET favorite_count = GREATEST(COALESCE(favorite_count, 0) - 1, 0),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $1
      RETURNING id, favorite_count
      `,
      [adId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'ad not found'
      });
    }

    res.json({
      success: true,
      ad_id: result.rows[0].id,
      favorite_count: result.rows[0].favorite_count
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router;
