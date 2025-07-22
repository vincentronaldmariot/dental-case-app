const { Pool } = require('pg');

const pool = new Pool({
  user: 'dental_user',
  host: 'localhost',
  database: 'dental_case_db',
  password: 'dental_password',
  port: 5432,
});

async function deleteInvalidSurveys() {
  try {
    const res = await pool.query(
      `DELETE FROM dental_surveys WHERE LENGTH(patient_id::text) != 36 OR patient_id::text !~ '^[0-9a-fA-F-]{36}$' RETURNING id, patient_id`
    );
    console.log(`Deleted ${res.rowCount} invalid survey(s).`);
    if (res.rows.length > 0) {
      console.log('Deleted survey IDs:', res.rows.map(r => r.id));
    }
  } catch (err) {
    console.error('Error deleting invalid surveys:', err);
  } finally {
    await pool.end();
  }
}

deleteInvalidSurveys(); 