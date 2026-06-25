const router = require('express').Router();
const upload = require('../middleware/upload');

router.post('/', upload.single('image'), (req, res) => {
  res.json({
    ok: true,
    filename: req.file.filename,
    url: '/uploads/' + req.file.filename
  });
});

router.post('/multiple', upload.array('images', 20), (req, res) => {
  const files = req.files || [];

  res.json({
    ok: true,
    count: files.length,
    images: files.map(file => ({
      filename: file.filename,
      url: '/uploads/' + file.filename
    }))
  });
});

module.exports = router;
