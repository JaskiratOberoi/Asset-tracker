const multer = require('multer');
const { getBucket } = require('./mongo');
const { ObjectId } = require('mongodb');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 50 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['application/pdf', 'image/jpeg', 'image/png', 'image/jpg', 'image/webp'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid file type'), false);
    }
  },
});

async function storeInGridFS(buffer, originalname, mimetype) {
  const bucket = getBucket();
  const id = new ObjectId();
  const stream = bucket.openUploadStreamWithId(id, originalname, {
    metadata: { originalname, mimetype },
  });
  return new Promise((resolve, reject) => {
    stream.write(buffer, (err) => {
      if (err) return reject(err);
      stream.end(() => resolve(id.toString()));
    });
  });
}

module.exports = { upload, storeInGridFS };
