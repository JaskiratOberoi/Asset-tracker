const express = require('express');
const { pool } = require('../db');

const router = express.Router();

// Public: list locations (for onboarding dropdown)
// Deduplicate by (company_id, name) so the same location never appears twice (e.g. if migration ran twice)
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT id, name, company_id FROM (
        SELECT id, name, company_id,
               ROW_NUMBER() OVER (PARTITION BY company_id, name ORDER BY id) AS rn
        FROM public.locations
      ) t WHERE rn = 1
       ORDER BY name`
    );
    res.json(result.rows);
  } catch (err) {
    console.error('Locations list error:', err);
    res.status(500).json({ error: 'Failed to load locations' });
  }
});

// Public: create location (onboarding combobox "add new")
router.post('/', async (req, res) => {
  try {
    const { name, company_id } = req.body;
    const companyId = company_id || req.body.companyId;
    if (!name || typeof name !== 'string' || !name.trim()) {
      return res.status(400).json({ error: 'Location name is required' });
    }
    if (!companyId) {
      return res.status(400).json({ error: 'Company is required to add a location' });
    }
    const result = await pool.query(
      `INSERT INTO public.locations (company_id, name)
       VALUES ($1, $2)
       RETURNING id, name, company_id`,
      [companyId, name.trim()]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Location create error:', err);
    res.status(500).json({ error: 'Failed to create location' });
  }
});

module.exports = router;
