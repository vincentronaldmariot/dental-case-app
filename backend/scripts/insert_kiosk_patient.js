const { Pool } = require('pg');

const pool = new Pool({
  user: 'dental_user',
  host: 'localhost',
  database: 'dental_case_db',
  password: 'dental_password',
  port: 5432,
});

async function insertKioskPatient() {
  try {
    const kioskId = '00000000-0000-0000-0000-000000000000';
    const email = 'kiosk@kiosk.com';
    const firstName = 'Kiosk';
    const lastName = 'Mode';
    const phone = '000-000-0000'; // Dummy phone number
    const passwordHash = 'kiosk_dummy_hash'; // Dummy password hash
    const dateOfBirth = '2000-01-01'; // Dummy date of birth
    await pool.query(
      `INSERT INTO patients (id, email, first_name, last_name, phone, password_hash, date_of_birth)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       ON CONFLICT (id) DO NOTHING;`,
      [kioskId, email, firstName, lastName, phone, passwordHash, dateOfBirth]
    );
    console.log('Kiosk patient inserted or already exists.');
  } catch (err) {
    console.error('Error inserting kiosk patient:', err);
  } finally {
    await pool.end();
  }
}

insertKioskPatient(); 