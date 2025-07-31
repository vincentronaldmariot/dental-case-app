const { Pool } = require('pg');

// Railway PostgreSQL connection details
// You'll need to get these from your Railway dashboard
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/dental_app',
  ssl: {
    rejectUnauthorized: false
  }
});

async function fixEmergencyDatabase() {
  console.log('🔧 Fixing Emergency Database Schema\n');

  try {
    // Test connection
    console.log('1️⃣ Testing database connection...');
    const client = await pool.connect();
    console.log('✅ Database connection successful');

    // Check current schema
    console.log('\n2️⃣ Checking current emergency_records schema...');
    const schemaQuery = `
      SELECT 
        column_name, 
        data_type, 
        is_nullable, 
        column_default
      FROM information_schema.columns 
      WHERE table_name = 'emergency_records' 
      ORDER BY ordinal_position;
    `;
    
    const schemaResult = await client.query(schemaQuery);
    console.log('Current columns:');
    schemaResult.rows.forEach(row => {
      console.log(`   - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    // Add missing columns
    console.log('\n3️⃣ Adding missing columns...');
    
    const addColumnsQueries = [
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'reported';",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS priority VARCHAR(50) DEFAULT 'standard';",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS handled_by VARCHAR(100);",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS resolution TEXT;",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS follow_up_required TEXT;",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP;",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS emergency_contact VARCHAR(100);",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS notes TEXT;"
    ];

    for (const query of addColumnsQueries) {
      try {
        await client.query(query);
        console.log('✅ Executed:', query.substring(0, 50) + '...');
      } catch (error) {
        console.log('⚠️  Warning:', error.message);
      }
    }

    // Update existing records with default values
    console.log('\n4️⃣ Updating existing records...');
    const updateQueries = [
      "UPDATE emergency_records SET status = 'reported' WHERE status IS NULL;",
      "UPDATE emergency_records SET priority = 'standard' WHERE priority IS NULL;"
    ];

    for (const query of updateQueries) {
      try {
        const result = await client.query(query);
        console.log('✅ Updated records:', result.rowCount);
      } catch (error) {
        console.log('⚠️  Warning:', error.message);
      }
    }

    // Add indexes for better performance
    console.log('\n5️⃣ Adding indexes...');
    const indexQueries = [
      "CREATE INDEX IF NOT EXISTS idx_emergency_records_status ON emergency_records(status);",
      "CREATE INDEX IF NOT EXISTS idx_emergency_records_priority ON emergency_records(priority);",
      "CREATE INDEX IF NOT EXISTS idx_emergency_records_patient_id ON emergency_records(patient_id);",
      "CREATE INDEX IF NOT EXISTS idx_emergency_records_emergency_date ON emergency_records(emergency_date);"
    ];

    for (const query of indexQueries) {
      try {
        await client.query(query);
        console.log('✅ Created index');
      } catch (error) {
        console.log('⚠️  Warning:', error.message);
      }
    }

    // Verify final schema
    console.log('\n6️⃣ Verifying final schema...');
    const finalSchemaResult = await client.query(schemaQuery);
    console.log('Final columns:');
    finalSchemaResult.rows.forEach(row => {
      console.log(`   - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    // Test a sample query
    console.log('\n7️⃣ Testing sample query...');
    const testQuery = `
      SELECT 
        er.id, er.patient_id, er.emergency_date, er.emergency_type, 
        er.description, er.severity, er.resolved, 
        COALESCE(er.status, 'reported') as status,
        COALESCE(er.priority, 'standard') as priority,
        er.handled_by, er.resolution, er.follow_up_required, er.resolved_at,
        er.emergency_contact, er.notes, er.created_at,
        p.first_name, p.last_name, p.email, p.phone
      FROM emergency_records er
      LEFT JOIN patients p ON er.patient_id = p.id
      LIMIT 1;
    `;
    
    try {
      const testResult = await client.query(testQuery);
      console.log('✅ Sample query successful');
      if (testResult.rows.length > 0) {
        console.log('   Sample record:', testResult.rows[0]);
      } else {
        console.log('   No emergency records found (this is normal if none exist)');
      }
    } catch (error) {
      console.log('❌ Sample query failed:', error.message);
    }

    client.release();
    console.log('\n🎉 Emergency database schema fix completed!');

  } catch (error) {
    console.log('❌ Database fix failed:', error.message);
    console.log('\n📋 MANUAL FIX REQUIRED:');
    console.log('1. Go to your Railway project dashboard');
    console.log('2. Click on your PostgreSQL database');
    console.log('3. Open the "Query" tab');
    console.log('4. Run the SQL commands from EMERGENCY_TAB_FIX_GUIDE.md');
  }
}

// Instructions for running this script
console.log('📋 INSTRUCTIONS:');
console.log('1. Get your Railway PostgreSQL connection string from Railway dashboard');
console.log('2. Set it as DATABASE_URL environment variable:');
console.log('   set DATABASE_URL=postgresql://username:password@host:port/database');
console.log('3. Run: node fix_emergency_database_direct.js');
console.log('\n⚠️  WARNING: This script will modify your database schema!');
console.log('Make sure you have a backup before proceeding.\n');

// Only run if DATABASE_URL is set
if (process.env.DATABASE_URL) {
  fixEmergencyDatabase().catch(console.error);
} else {
  console.log('❌ DATABASE_URL environment variable not set.');
  console.log('Please set it with your Railway PostgreSQL connection string.');
} 