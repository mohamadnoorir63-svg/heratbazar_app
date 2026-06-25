require('dotenv').config();
const express = require('express');
const cors = require('cors');

const statusRoutes = require('./routes/status');
const categoriesRoutes = require('./routes/categories');
const adsRoutes = require('./routes/ads');
const uploadsRoutes = require('./routes/uploads');
const authRoutes = require('./routes/auth');
const chatRoutes = require('./routes/chat');
const adminRoutes = require('./routes/admin');
const usersRoutes = require('./routes/users');
const groupRoutes = require('./routes/group');

const app = express();

app.use(cors());
app.use(express.json());
app.use('/uploads', express.static('public/uploads'));

app.use('/api/status', statusRoutes);
app.use('/api/categories', categoriesRoutes);
app.use('/api/ads', adsRoutes);
app.use('/api/uploads', uploadsRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/group', groupRoutes);

const PORT = process.env.PORT || 4001;
app.listen(PORT, () => {
  console.log(`HeratBazar API running on port ${PORT}`);
});
