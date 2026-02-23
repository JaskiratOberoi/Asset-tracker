const express = require('express');
const { pool } = require('../db');

const router = express.Router();

// Public: list locations (for onboarding dropdown)
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, name, company_id FROM public.locations ORDER BY name'
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Locations list error:', err);
    res.status(500).json({ error: 'Failed to load locations' });
  }
});

module.exports = router;
