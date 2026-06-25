require('dotenv').config();
const express = require('express');
const cors = require('cors');

const statusRoutes = require('./routes/status');
const categoriesRoutes = require('./routes/categories');
const adsRoutes = require('./routes/ads');
const uploadsRoutes = require('./routes/uploads');
const authRoutes = require('./routes/auth');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('public/uploads'));

app.use('/api/status', statusRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/ads', adsRoutes);
app.use('/api/uploads', uploadsRoutes);
app.use('/api/auth', authRoutes);

const PORT = process.env.PORT || 4001;
app.listen(PORT, () => {
  console.log(`HeratBazar API running on port ${PORT}`);
});
