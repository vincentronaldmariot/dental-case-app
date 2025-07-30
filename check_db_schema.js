const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

async function checkDbSchema() {
  try {
    console.log('🔍 Checking Database Schema...\n');

    const client = await pool.connect();

    // Check table structure
    console.log('📋 Checking patients table structure...');
    const tableStructure = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'patients' 
      ORDER BY ordinal_position;
    `);
    
    console.log('Patients table columns:');
    tableStructure.rows.forEach((row, index) => {
      console.log(`  ${index + 1}. ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable}, default: ${row.column_default})`);
    });

    // Check recent patients to see what's actually stored
    console.log('\n📋 Checking recent patients...');
    const recentPatients = await client.query(`
      SELECT id, first_name, last_name, email, phone, password_hash, created_at
      FROM patients 
      ORDER BY created_at DESC 
      LIMIT 3;
    `);
    
    console.log('Recent patients:');
    recentPatients.rows.forEach((patient, index) => {
      console.log(`\n  Patient ${index + 1}:`);
      console.log(`    ID: ${patient.id}`);
      console.log(`    Name: ${patient.first_name} ${patient.last_name}`);
      console.log(`    Email: ${patient.email}`);
      console.log(`    Phone: ${patient.phone}`);
      console.log(`    Password hash: ${patient.password_hash ? 'Present' : 'Missing'}`);
      console.log(`    Created: ${patient.created_at}`);
    });

    client.release();

  } catch (error) {
    console.error('❌ Database check failed:', error.message);
  } finally {
    await pool.end();
  }
}

// Run the check
checkDbSchema();