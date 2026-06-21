const router = require('express').Router();
const upload = require('../middleware/upload');

router.post('/', upload.single('image'), (req, res) => {
  res.json({
    ok: true,
    filename: req.file.filename,
    url: '/uploads/' + req.file.filename
  });
});

module.exports = router;
