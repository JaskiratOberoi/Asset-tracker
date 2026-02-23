const express = require('express');
const { requireAdmin } = require('../middleware/auth');
const { getBucket } = require('../mongo');
const { ObjectId } = require('mongodb');

const router = express.Router();

// Admin: stream file by MongoDB ObjectId (stored in assets.bill_url)
router.get('/:id', requireAdmin, async (req, res) => {
  try {
    const id = req.params.id;
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ error: 'Invalid file id' });
    }
    const bucket = getBucket();
    const cursor = bucket.find({ _id: new ObjectId(id) });
    const file = await cursor.next();
    if (!file) {
      return res.status(404).json({ error: 'File not found' });
    }
    res.setHeader('Content-Type', file.metadata?.mimetype || 'application/octet-stream');
    if (file.metadata?.originalname) {
      res.setHeader('Content-Disposition', `inline; filename="${file.metadata.originalname}"`);
    }
    const downloadStream = bucket.openDownloadStream(new ObjectId(id));
    downloadStream.pipe(res);
  } catch (err) {
    console.error('File get error:', err);
    res.status(500).json({ error: 'Failed to get file' });
  }
});

module.exports = router;
