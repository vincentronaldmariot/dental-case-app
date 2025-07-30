const { Pool } = require('pg');

async function fixMissingColumns() {
  console.log('🔧 Fixing Missing Database Columns...\n');

  const dbConfig = {
    host: 'ballast.proxy.rlwy.net',
    port: 27199,
    database: 'railway',
    user: 'postgres',
    password: 'glfJbkmkHHAAlKQqFzNtkMQjXOPjJthr',
    ssl: false
  };

  let pool = null;
  try {
    pool = new Pool(dbConfig);
    const client = await pool.connect();
    console.log('✅ Connected to database');

    // Fix 1: Add missing columns to patients table
    console.log('\n📋 Fix 1: Adding missing columns to patients table...');
    try {
      await client.query(`
        ALTER TABLE patients 
        ADD COLUMN IF NOT EXISTS emergency_contact VARCHAR(255),
        ADD COLUMN IF NOT EXISTS emergency_phone VARCHAR(20),
        ADD COLUMN IF NOT EXISTS medical_history TEXT,
        ADD COLUMN IF NOT EXISTS allergies TEXT,
        ADD COLUMN IF NOT EXISTS admin_notes TEXT
      `);
      console.log('✅ Added missing columns to patients table');
    } catch (error) {
      console.log('❌ Error adding columns to patients:', error.message);
    }

    // Fix 2: Add missing columns to emergency_records table
    console.log('\n📋 Fix 2: Adding missing columns to emergency_records table...');
    try {
      await client.query(`
        ALTER TABLE emergency_records 
        ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'reported',
        ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'medium',
        ADD COLUMN IF NOT EXISTS handled_by VARCHAR(255),
        ADD COLUMN IF NOT EXISTS resolution TEXT,
        ADD COLUMN IF NOT EXISTS follow_up_required TEXT,
        ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP WITH TIME ZONE
      `);
      console.log('✅ Added missing columns to emergency_records table');
    } catch (error) {
      console.log('❌ Error adding columns to emergency_records:', error.message);
    }

    // Fix 3: Add missing columns to appointments table
    console.log('\n📋 Fix 3: Adding missing columns to appointments table...');
    try {
      await client.query(`
        ALTER TABLE appointments 
        ADD COLUMN IF NOT EXISTS time_slot VARCHAR(50),
        ADD COLUMN IF NOT EXISTS notes TEXT,
        ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      `);
      console.log('✅ Added missing columns to appointments table');
    } catch (error) {
      console.log('❌ Error adding columns to appointments:', error.message);
    }

    // Fix 4: Add missing columns to dental_surveys table
    console.log('\n📋 Fix 4: Adding missing columns to dental_surveys table...');
    try {
      await client.query(`
        ALTER TABLE dental_surveys 
        ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE,
        ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      `);
      console.log('✅ Added missing columns to dental_surveys table');
    } catch (error) {
      console.log('❌ Error adding columns to dental_surveys:', error.message);
    }

    // Verify the fixes
    console.log('\n📋 Verifying fixes...');
    try {
      const patientsResult = await client.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'patients' 
        AND column_name IN ('emergency_contact', 'emergency_phone', 'medical_history', 'allergies', 'admin_notes')
      `);
      console.log('✅ Patients table columns:', patientsResult.rows.map(row => row.column_name));

      const emergencyResult = await client.query(`
        SELECT column_name 
        FROM information_schema.columns 
        WHERE table_name = 'emergency_records' 
        AND column_name IN ('status', 'priority', 'handled_by', 'resolution', 'follow_up_required', 'resolved_at')
      `);
      console.log('✅ Emergency records table columns:', emergencyResult.rows.map(row => row.column_name));

    } catch (error) {
      console.log('❌ Error verifying fixes:', error.message);
    }

    client.release();
    console.log('\n🎉 Database schema fixes completed!');
    console.log('\n📋 Next Steps:');
    console.log('1. Test the admin dashboard again');
    console.log('2. Run: node final_admin_fix_test.js');

  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
  } finally {
    if (pool) {
      await pool.end();
      console.log('🔌 Database connection closed');
    }
  }
}

fixMissingColumns(); 