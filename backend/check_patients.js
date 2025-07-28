const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'dental_case_db',
  password: process.env.DB_PASSWORD || 'your_password',
  port: process.env.DB_PORT || 5432,
});

async function checkPatients() {
  try {
    console.log('🔍 Checking patients table structure...');
    
    // First check the table structure
    const structureResult = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'patients'
      ORDER BY ordinal_position
    `);
    
    console.log('📋 Patients table structure:');
    structureResult.rows.forEach((column, index) => {
      console.log(`${index + 1}. ${column.column_name} (${column.data_type}, nullable: ${column.is_nullable})`);
    });
    
    console.log('\n🔍 Checking patients in database...');
    
    const result = await pool.query(`
      SELECT id, first_name, last_name, email, phone 
      FROM patients 
      ORDER BY created_at DESC 
      LIMIT 10
    `);
    
    console.log('📋 Found patients:');
    result.rows.forEach((patient, index) => {
      console.log(`${index + 1}. ID: ${patient.id}`);
      console.log(`   Name: ${patient.first_name} ${patient.last_name}`);
      console.log(`   Email: ${patient.email}`);
      console.log(`   Phone: ${patient.phone}`);
      console.log('');
    });
    
  } catch (error) {
    console.error('❌ Error checking patients:', error);
  } finally {
    await pool.end();
  }
}

checkPatients(); 