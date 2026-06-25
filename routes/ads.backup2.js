const router = require('express').Router();
const db = require('../db');

router.get('/', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT ads.*, categories.name AS category_name
      FROM ads
      LEFT JOIN categories ON categories.id = ads.category_id
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
      image_url
    } = req.body;

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
        image_url
      )
      VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)
      RETURNING *
    `, [
      title,
      description,
      price,
      phone,
      city || province || 'Herat',
      province || null,
      district || null,
      category_id,
      image_url || null
    ]);

    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
