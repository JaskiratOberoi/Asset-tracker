const express = require('express');
const { pool } = require('../db');
const { requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Public: create asset (onboarding) - file upload handled in index with multer
router.post('/', async (req, res) => {
  try {
    const { name, details, serial_number, company_id, location_id, bill_url } = req.body;
    if (!name || !company_id) {
      return res.status(400).json({ error: 'Name and company_id required' });
    }
    const result = await pool.query(
      `INSERT INTO public.assets (name, details, serial_number, company_id, location_id, bill_url)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [
        name,
        details ? JSON.stringify(details) : null,
        serial_number && serial_number.trim() ? serial_number.trim() : null,
        company_id,
        location_id || null,
        bill_url || null,
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Asset create error:', err);
    res.status(500).json({ error: 'Failed to create asset' });
  }
});

// Admin: list assets with company and location names
router.get('/', requireAdmin, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT a.id, a.name, a.details, a.serial_number, a.company_id, a.location_id, a.bill_url, a.created_at,
              c.name AS company_name,
              l.name AS location_name
       FROM public.assets a
       LEFT JOIN public.companies c ON c.id = a.company_id
       LEFT JOIN public.locations l ON l.id = a.location_id
       ORDER BY a.created_at DESC`
    );
    const rows = result.rows.map((r) => ({
      id: r.id,
      name: r.name,
      details: r.details,
      serial_number: r.serial_number,
      company_id: r.company_id,
      location_id: r.location_id,
      bill_url: r.bill_url,
      created_at: r.created_at,
      companies: r.company_name ? { name: r.company_name } : null,
      locations: r.location_name ? { name: r.location_name } : null,
    }));
    res.json(rows);
  } catch (err) {
    console.error('Assets list error:', err);
    res.status(500).json({ error: 'Failed to load assets' });
  }
});

// Admin: asset count by company (for charts)
router.get('/count-by-company', requireAdmin, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT c.id, c.name, COUNT(a.id)::int AS count
       FROM public.companies c
       LEFT JOIN public.assets a ON a.company_id = c.id
       GROUP BY c.id, c.name
       ORDER BY c.name`
    );
    res.json(result.rows.map((r) => ({ id: r.id, name: r.name, assetCount: r.count })));
  } catch (err) {
    console.error('Count by company error:', err);
    res.status(500).json({ error: 'Failed to load counts' });
  }
});

module.exports = router;
