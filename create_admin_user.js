const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

const pool = new Pool({
  user: 'dental_user',
  host: 'localhost',
  database: 'dental_case_db',
  password: 'dental_password',
  port: 5432,
});

async function createAdmin() {
  const username = 'admin';
  const fullName = 'System Administrator';
  const password = 'admin123';
  const hashedPassword = await bcrypt.hash(password, 12);
  const role = 'admin';
  const isActive = true;

  try {
    const result = await pool.query(
      `INSERT INTO admin_users (username, full_name, password_hash, role, is_active)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (username) DO NOTHING RETURNING *`,
      [username, fullName, hashedPassword, role, isActive]
    );
    if (result.rows.length > 0) {
      console.log('Admin user created:', result.rows[0]);
    } else {
      console.log('Admin user already exists.');
    }
  } catch (err) {
    console.error('Error creating admin user:', err);
  } finally {
    await pool.end();
  }
}

createAdmin(); 