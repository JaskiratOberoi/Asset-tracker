const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../db');
const { requireAdmin, JWT_SECRET } = require('../middleware/auth');

const router = express.Router();

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }
    const userResult = await pool.query(
      'SELECT id, email, password_hash FROM public.users WHERE email = $1',
      [email.trim().toLowerCase()]
    );
    if (userResult.rows.length === 0) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    const user = userResult.rows[0];
    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    const adminResult = await pool.query(
      'SELECT 1 FROM public.admin_users WHERE user_id = $1',
      [user.id]
    );
    if (adminResult.rows.length === 0) {
      return res.status(403).json({ error: 'Admin access required' });
    }
    const token = jwt.sign(
      { sub: user.id, email: user.email },
      JWT_SECRET,
      { expiresIn: '7d' }
    );
    res.json({
      token,
      user: { id: user.id, email: user.email },
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Login failed' });
  }
});

router.get('/me', requireAdmin, (req, res) => {
  res.json({ user: req.user });
});

module.exports = router;
