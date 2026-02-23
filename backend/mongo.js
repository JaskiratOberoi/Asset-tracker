const { MongoClient, GridFSBucket, ObjectId } = require('mongodb');

let client;
let db;
let bucket;

async function connectMongo() {
  const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/asset_tracker';
  client = new MongoClient(uri);
  await client.connect();
  db = client.db('asset_tracker');
  bucket = new GridFSBucket(db, { bucketName: 'bills' });
  return { db, bucket, client };
}

function getBucket() {
  if (!bucket) throw new Error('MongoDB not connected');
  return bucket;
}

function getDb() {
  if (!db) throw new Error('MongoDB not connected');
  return db;
}

function getClient() {
  return client;
}

module.exports = {
  connectMongo,
  getBucket,
  getDb,
  getClient,
  ObjectId,
};
