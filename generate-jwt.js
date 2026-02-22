// Generate JWT tokens for Supabase anon and service_role keys
const crypto = require('crypto');

const JWT_SECRET = 'your-super-secret-jwt-token-with-at-least-32-characters-long';

function base64UrlEncode(str) {
  return Buffer.from(str)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');
}

function createJWT(payload) {
  const header = {
    alg: 'HS256',
    typ: 'JWT'
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  
  const signature = crypto
    .createHmac('sha256', JWT_SECRET)
    .update(`${encodedHeader}.${encodedPayload}`)
    .digest('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '');

  return `${encodedHeader}.${encodedPayload}.${signature}`;
}

// Anon key - expires in 1 year
const anonPayload = {
  iss: 'supabase-demo',
  role: 'anon',
  exp: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60) // 1 year
};

// Service role key - expires in 1 year
const serviceRolePayload = {
  iss: 'supabase-demo',
  role: 'service_role',
  exp: Math.floor(Date.now() / 1000) + (365 * 24 * 60 * 60) // 1 year
};

const anonKey = createJWT(anonPayload);
const serviceRoleKey = createJWT(serviceRolePayload);

console.log('ANON_KEY:', anonKey);
console.log('\nSERVICE_ROLE_KEY:', serviceRoleKey);
