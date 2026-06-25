const router = require('express').Router();
const db = require('../db');

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
      ORDER BY ads.id DESC
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
      owner_token
    } = req.body;

    if (!owner_token) {
      return res.status(400).json({ error: 'owner_token required' });
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
        owner_token
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)
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
      owner_token
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
      owner_token
    } = req.body;

    if (!owner_token) {
      return res.status(400).json({ error: 'owner_token required' });
    }

    const check = await db.query(
      'SELECT * FROM ads WHERE id = $1',
      [adId]
    );

    if (check.rows.length === 0) {
      return res.status(404).json({ error: 'ad not found' });
    }

    const oldAd = check.rows[0];

    if (oldAd.owner_token !== owner_token) {
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
        updated_at = CURRENT_TIMESTAMP
      WHERE id = $10
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

router.delete('/:id', async (req, res) => {
  try {
    const adId = req.params.id;
    const owner_token = req.body.owner_token || req.query.owner_token;

    if (!owner_token) {
      return res.status(400).json({ error: 'owner_token required' });
    }

    const check = await db.query(
      'SELECT * FROM ads WHERE id = $1',
      [adId]
    );

    if (check.rows.length === 0) {
      return res.status(404).json({ error: 'ad not found' });
    }

    const ad = check.rows[0];

    if (ad.owner_token !== owner_token) {
      return res.status(403).json({ error: 'not allowed' });
    }

    await db.query('DELETE FROM ads WHERE id = $1', [adId]);

    res.json({ ok: true, deleted_id: adId });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
