require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });
const bcrypt = require('bcryptjs');
const { pool } = require('../db');

const readline = require('readline');
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

function question(prompt) {
  return new Promise((resolve) => rl.question(prompt, resolve));
}

async function main() {
  const email = process.env.ADMIN_EMAIL || (await question('Admin email: '));
  const password = process.env.ADMIN_PASSWORD || (await question('Admin password: '));
  rl.close();

  if (!email || !password) {
    console.error('Email and password required');
    process.exit(1);
  }

  const password_hash = await bcrypt.hash(password.trim(), 10);
  const client = await pool.connect();
  try {
    const insertUser = await client.query(
      `INSERT INTO public.users (email, password_hash)
       VALUES ($1, $2)
       ON CONFLICT (email) DO UPDATE SET password_hash = EXCLUDED.password_hash
       RETURNING id`,
      [email.trim().toLowerCase(), password_hash]
    );
    const userId = insertUser.rows[0].id;
    await client.query(
      `INSERT INTO public.admin_users (user_id) VALUES ($1)
       ON CONFLICT (user_id) DO NOTHING`,
      [userId]
    );
    console.log('Admin user created/updated:', email);
    console.log('You can now log in at the login page with this email and password.');
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  } finally {
    client.release();
    process.exit(0);
  }
}

main();
