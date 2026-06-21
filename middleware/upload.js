const multer = require('multer');
const path = require('path');

const storage = multer.diskStorage({
  destination: process.env.UPLOAD_DIR || '/opt/heratbazar/public/uploads',
  filename: (req, file, cb) => {
    const unique = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, unique + path.extname(file.originalname));
  }
});

module.exports = multer({ storage });
