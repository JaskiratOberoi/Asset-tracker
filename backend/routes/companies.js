const express = require('express');
const { pool } = require('../db');

const router = express.Router();

// Public: list companies (for onboarding dropdown)
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name FROM public.companies ORDER BY name'
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Companies list error:', err);
    res.status(500).json({ error: 'Failed to load companies' });
  }
});

module.exports = router;
