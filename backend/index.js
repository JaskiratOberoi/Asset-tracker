require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { pool } = require('./db');
const { connectMongo, getBucket } = require('./mongo');
const { upload, storeInGridFS } = require('./upload');
const authRoutes = require('./routes/auth');
const companiesRoutes = require('./routes/companies');
const locationsRoutes = require('./routes/locations');
const assetsRoutes = require('./routes/assets');
const filesRoutes = require('./routes/files');

const PORT = process.env.PORT || 4000;

async function runMigrations() {
  const migrationsDir = path.join(__dirname, 'migrations');
  const files = fs.readdirSync(migrationsDir).filter((f) => f.endsWith('.sql')).sort();
  for (const file of files) {
    const sql = fs.readFileSync(path.join(migrationsDir, file), 'utf8');
    try {
      await pool.query(sql);
      console.log('Ran migration:', file);
    } catch (e) {
      if (e.code === '42P07' || e.code === '42710') {
        console.log('Skipped (already applied):', file);
      } else {
        throw e;
      }
    }
  }
}

const app = express();
app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

// Public: create asset with optional file (multipart)
app.post('/api/assets', upload.single('billFile'), async (req, res) => {
  try {
    let billUrl = null;
    if (req.file) {
      const fileId = await storeInGridFS(
        req.file.buffer,
        req.file.originalname,
        req.file.mimetype
      );
      billUrl = fileId;
    }
    const body = req.body || {};
    const name = body.name;
    const company_id = body.companyId || body.company_id;
    if (!name || !company_id) {
      return res.status(400).json({ error: 'Name and company_id required' });
    }
    const details = body.description
      ? { description: body.description }
      : body.details
        ? (typeof body.details === 'string' ? JSON.parse(body.details) : body.details)
        : null;
    const serial_number =
      body.serialNumber && body.serialNumber.trim()
        ? body.serialNumber.trim()
        : body.serial_number && body.serial_number.trim()
          ? body.serial_number.trim()
          : null;
    const location_id = body.locationId || body.location_id || null;

    const result = await pool.query(
      `INSERT INTO public.assets (name, details, serial_number, company_id, location_id, bill_url)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [name, details ? JSON.stringify(details) : null, serial_number, company_id, location_id, billUrl]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('Asset create error:', err);
    res.status(500).json({ error: err.message || 'Failed to create asset' });
  }
});

app.use('/api/auth', authRoutes);
app.use('/api/companies', companiesRoutes);
app.use('/api/locations', locationsRoutes);
app.use('/api/assets', assetsRoutes);
app.use('/api/files', filesRoutes);

app.get('/health', (req, res) => res.json({ ok: true }));

async function start() {
  try {
    await pool.query('SELECT 1');
    console.log('Postgres connected');
  } catch (e) {
    console.error('Postgres connection failed:', e.message);
    process.exit(1);
  }
  try {
    await connectMongo();
    console.log('MongoDB connected');
  } catch (e) {
    console.error('MongoDB connection failed:', e.message);
    process.exit(1);
  }
  try {
    await runMigrations();
  } catch (e) {
    console.error('Migration error:', e);
    process.exit(1);
  }
  app.listen(PORT, () => console.log('API listening on port', PORT));
}

start().catch((err) => {
  console.error(err);
  process.exit(1);
});
