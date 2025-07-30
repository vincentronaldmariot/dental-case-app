const { Pool } = require('pg');

async function fixRemainingColumns() {
  console.log('🔧 Fixing Remaining Missing Database Columns...\n');

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

    // Check what columns exist in each table
    console.log('\n📋 Checking current table schemas...');
    
    const tables = ['patients', 'appointments', 'emergency_records', 'dental_surveys'];
    
    for (const table of tables) {
      try {
        const result = await client.query(`
          SELECT column_name, data_type 
          FROM information_schema.columns 
          WHERE table_name = '${table}' 
          ORDER BY ordinal_position
        `);
        console.log(`\n📊 ${table} table columns:`);
        result.rows.forEach(row => {
          console.log(`  - ${row.column_name}: ${row.data_type}`);
        });
      } catch (error) {
        console.log(`❌ Error checking ${table} table:`, error.message);
      }
    }

    // Fix any remaining missing columns based on the admin routes
    console.log('\n🔧 Adding any remaining missing columns...');
    
    // Check if we need to add more columns to patients table
    try {
      await client.query(`
        ALTER TABLE patients 
        ADD COLUMN IF NOT EXISTS classification VARCHAR(100),
        ADD COLUMN IF NOT EXISTS other_classification VARCHAR(255),
        ADD COLUMN IF NOT EXISTS serial_number VARCHAR(100),
        ADD COLUMN IF NOT EXISTS unit_assignment VARCHAR(100),
        ADD COLUMN IF NOT EXISTS date_of_birth DATE
      `);
      console.log('✅ Added additional columns to patients table');
    } catch (error) {
      console.log('❌ Error adding columns to patients:', error.message);
    }

    // Check if we need to add more columns to appointments table
    try {
      await client.query(`
        ALTER TABLE appointments 
        ADD COLUMN IF NOT EXISTS service VARCHAR(255),
        ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'pending'
      `);
      console.log('✅ Added additional columns to appointments table');
    } catch (error) {
      console.log('❌ Error adding columns to appointments:', error.message);
    }

    // Check if we need to add more columns to emergency_records table
    try {
      await client.query(`
        ALTER TABLE emergency_records 
        ADD COLUMN IF NOT EXISTS emergency_type VARCHAR(100),
        ADD COLUMN IF NOT EXISTS description TEXT,
        ADD COLUMN IF NOT EXISTS pain_level INTEGER,
        ADD COLUMN IF NOT EXISTS symptoms TEXT[],
        ADD COLUMN IF NOT EXISTS location VARCHAR(255),
        ADD COLUMN IF NOT EXISTS duty_related BOOLEAN DEFAULT false,
        ADD COLUMN IF NOT EXISTS unit_command VARCHAR(255),
        ADD COLUMN IF NOT EXISTS first_aid_provided TEXT,
        ADD COLUMN IF NOT EXISTS emergency_contact VARCHAR(255),
        ADD COLUMN IF NOT EXISTS notes TEXT
      `);
      console.log('✅ Added additional columns to emergency_records table');
    } catch (error) {
      console.log('❌ Error adding columns to emergency_records:', error.message);
    }

    // Test a simple query to see if the schema is now complete
    console.log('\n🧪 Testing admin queries...');
    try {
      const patientsTest = await client.query('SELECT COUNT(*) as count FROM patients');
      console.log('✅ Patients count query:', patientsTest.rows[0].count);
      
      const appointmentsTest = await client.query('SELECT COUNT(*) as count FROM appointments');
      console.log('✅ Appointments count query:', appointmentsTest.rows[0].count);
      
      const emergencyTest = await client.query('SELECT COUNT(*) as count FROM emergency_records');
      console.log('✅ Emergency records count query:', emergencyTest.rows[0].count);
      
      const surveysTest = await client.query('SELECT COUNT(*) as count FROM dental_surveys');
      console.log('✅ Surveys count query:', surveysTest.rows[0].count);
      
    } catch (error) {
      console.log('❌ Test query failed:', error.message);
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

fixRemainingColumns(); 