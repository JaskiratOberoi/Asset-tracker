const express = require('express');
const { pool } = require('../db');
const { requireAdmin } = require('../middleware/auth');
const { getBucket, ObjectId } = require('../mongo');

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

// Admin: list assets with company, location, and acknowledgement status
router.get('/', requireAdmin, async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT a.id, a.name, a.details, a.serial_number, a.company_id, a.location_id, a.bill_url, a.created_at, a.acknowledged_at,
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
      acknowledged_at: r.acknowledged_at,
      companies: r.company_name ? { name: r.company_name } : null,
      locations: r.location_name ? { name: r.location_name } : null,
    }));
    res.json(rows);
  } catch (err) {
    console.error('Assets list error:', err);
    res.status(500).json({ error: 'Failed to load assets' });
  }
});

// Admin: acknowledge an asset (onboarding was done by anyone; admin confirms) — must be before /:id
router.patch('/:id/acknowledge', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await pool.query(
      `UPDATE public.assets SET acknowledged_at = COALESCE(acknowledged_at, NOW()) WHERE id = $1 RETURNING id, acknowledged_at`,
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Asset not found' });
    }
    res.json({ id: result.rows[0].id, acknowledged_at: result.rows[0].acknowledged_at });
  } catch (err) {
    console.error('Acknowledge error:', err);
    res.status(500).json({ error: 'Failed to acknowledge asset' });
  }
});

// Admin: update asset (description and/or serial_number)
router.patch('/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { description, serial_number } = req.body;
    const updates = [];
    const values = [];
    let paramIndex = 1;
    if (serial_number !== undefined) {
      updates.push(`serial_number = $${paramIndex}`);
      values.push(serial_number && serial_number.trim() ? serial_number.trim() : null);
      paramIndex++;
    }
    if (description !== undefined) {
      updates.push(`details = COALESCE(details, '{}'::jsonb) || jsonb_build_object('description', $${paramIndex}::text)`);
      values.push(description);
      paramIndex++;
    }
    if (updates.length === 0) {
      return res.status(400).json({ error: 'Provide description and/or serial_number' });
    }
    values.push(id);
    const result = await pool.query(
      `UPDATE public.assets SET ${updates.join(', ')} WHERE id = $${paramIndex} RETURNING id, name, details, serial_number, company_id, location_id, bill_url, created_at, acknowledged_at`,
      values
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Asset not found' });
    }
    const row = result.rows[0];
    res.json({
      id: row.id,
      name: row.name,
      details: row.details,
      serial_number: row.serial_number,
      company_id: row.company_id,
      location_id: row.location_id,
      bill_url: row.bill_url,
      created_at: row.created_at,
      acknowledged_at: row.acknowledged_at,
    });
  } catch (err) {
    console.error('Update asset error:', err);
    res.status(500).json({ error: 'Failed to update asset' });
  }
});

// Admin: delete an asset (with optional GridFS file cleanup)
router.delete('/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const assetResult = await pool.query('SELECT id, bill_url FROM public.assets WHERE id = $1', [id]);
    if (assetResult.rows.length === 0) {
      return res.status(404).json({ error: 'Asset not found' });
    }
    const billUrl = assetResult.rows[0].bill_url;
    if (billUrl && ObjectId.isValid(billUrl)) {
      try {
        const bucket = getBucket();
        await bucket.delete(new ObjectId(billUrl));
      } catch (e) {
        console.warn('GridFS delete skip:', e.message);
      }
    }
    await pool.query('DELETE FROM public.assets WHERE id = $1', [id]);
    res.status(204).send();
  } catch (err) {
    console.error('Delete asset error:', err);
    res.status(500).json({ error: 'Failed to delete asset' });
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
