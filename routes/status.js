const router = require('express').Router();

router.get('/', (req, res) => {
  res.json({
    ok: true,
    project: 'HeratBazar',
    message: 'API آماده است'
  });
});

module.exports = router;
