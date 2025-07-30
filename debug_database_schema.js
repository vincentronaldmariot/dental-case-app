const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

async function debugDatabaseSchema() {
  try {
    console.log('🔍 Debugging Database Schema...\n');

    const client = await pool.connect();

    // Check table structure
    console.log('📋 Step 1: Checking patients table structure...');
    const tableStructure = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'patients' 
      ORDER BY ordinal_position;
    `);
    
    console.log('Patients table columns:');
    tableStructure.rows.forEach(row => {
      console.log(`  ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable}, default: ${row.column_default})`);
    });

    // Check recent patients
    console.log('\n📋 Step 2: Checking recent patients...');
    const recentPatients = await client.query(`
      SELECT id, first_name, last_name, email, phone, created_at
      FROM patients 
      ORDER BY created_at DESC 
      LIMIT 5;
    `);
    
    console.log('Recent patients:');
    recentPatients.rows.forEach(patient => {
      console.log(`  ID: ${patient.id} (type: ${typeof patient.id})`);
      console.log(`  Name: ${patient.first_name} ${patient.last_name}`);
      console.log(`  Email: ${patient.email}`);
      console.log(`  Phone: ${patient.phone}`);
      console.log(`  Created: ${patient.created_at}`);
      console.log('  ---');
    });

    // Check specific patient by email
    console.log('\n📋 Step 3: Checking specific patient by email...');
    const specificPatient = await client.query(`
      SELECT id, first_name, last_name, email, phone, password_hash, created_at
      FROM patients 
      WHERE email = 'debugpatient@example.com';
    `);
    
    if (specificPatient.rows.length > 0) {
      const patient = specificPatient.rows[0];
      console.log('Found debug patient:');
      console.log(`  ID: ${patient.id} (type: ${typeof patient.id})`);
      console.log(`  Name: ${patient.first_name} ${patient.last_name}`);
      console.log(`  Email: ${patient.email}`);
      console.log(`  Phone: ${patient.phone}`);
      console.log(`  Password hash: ${patient.password_hash ? 'Present' : 'Missing'}`);
      console.log(`  Created: ${patient.created_at}`);
    } else {
      console.log('Debug patient not found in database');
    }

    // Check if there are any patients with numeric IDs
    console.log('\n📋 Step 4: Checking for numeric IDs...');
    const numericIds = await client.query(`
      SELECT id, first_name, last_name, email
      FROM patients 
      WHERE id ~ '^[0-9]+$'
      LIMIT 5;
    `);
    
    if (numericIds.rows.length > 0) {
      console.log('Patients with numeric IDs:');
      numericIds.rows.forEach(patient => {
        console.log(`  ID: ${patient.id} - ${patient.first_name} ${patient.last_name} (${patient.email})`);
      });
    } else {
      console.log('No patients with numeric IDs found');
    }

    // Check if there are any patients with UUID format
    console.log('\n📋 Step 5: Checking for UUID format IDs...');
    const uuidIds = await client.query(`
      SELECT id, first_name, last_name, email
      FROM patients 
      WHERE id ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      LIMIT 5;
    `);
    
    if (uuidIds.rows.length > 0) {
      console.log('Patients with UUID format IDs:');
      uuidIds.rows.forEach(patient => {
        console.log(`  ID: ${patient.id} - ${patient.first_name} ${patient.last_name} (${patient.email})`);
      });
    } else {
      console.log('No patients with UUID format IDs found');
    }

    client.release();

  } catch (error) {
    console.error('❌ Database debug failed:', error.message);
  } finally {
    await pool.end();
  }
}

// Run the debug
debugDatabaseSchema();