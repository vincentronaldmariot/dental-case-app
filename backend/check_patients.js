const { Pool } = require('pg');

const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'dental_case_db',
  user: 'dental_user',
  password: 'dental_password',
});

async function checkPatients() {
  try {
    console.log('🔍 Checking patients in database...\n');
    
    const result = await pool.query(`
      SELECT id, first_name, last_name, email, phone
      FROM patients
      ORDER BY created_at DESC
      LIMIT 10
    `);
    
    console.log(`📊 Found ${result.rows.length} patients:\n`);
    
    result.rows.forEach((patient, index) => {
      console.log(`${index + 1}. ${patient.first_name} ${patient.last_name}`);
      console.log(`   Email: ${patient.email}`);
      console.log(`   Phone: ${patient.phone}`);
      console.log(`   ID: ${patient.id}`);
      console.log('');
    });
    
  } catch (error) {
    console.error('❌ Error checking patients:', error);
  } finally {
    await pool.end();
  }
}

checkPatients(); 