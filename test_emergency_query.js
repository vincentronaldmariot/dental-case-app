const { Pool } = require('pg');

// This script will test the exact emergency query that's failing
// You'll need to set your Railway DATABASE_URL as environment variable

async function testEmergencyQuery() {
  console.log('🔍 Testing Emergency Query Directly\n');

  if (!process.env.DATABASE_URL) {
    console.log('❌ DATABASE_URL environment variable not set.');
    console.log('Please set it with your Railway PostgreSQL connection string.');
    console.log('Example: set DATABASE_URL=postgresql://username:password@host:port/database');
    return;
  }

  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
      rejectUnauthorized: false
    }
  });

  try {
    console.log('1️⃣ Connecting to database...');
    const client = await pool.connect();
    console.log('✅ Database connection successful');

    // Test 1: Check if emergency_records table exists
    console.log('\n2️⃣ Checking emergency_records table...');
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'emergency_records'
      );
    `);
    
    if (tableCheck.rows[0].exists) {
      console.log('✅ emergency_records table exists');
    } else {
      console.log('❌ emergency_records table does not exist');
      return;
    }

    // Test 2: Check table schema
    console.log('\n3️⃣ Checking table schema...');
    const schemaCheck = await client.query(`
      SELECT 
        column_name, 
        data_type, 
        is_nullable, 
        column_default
      FROM information_schema.columns 
      WHERE table_name = 'emergency_records' 
      ORDER BY ordinal_position;
    `);
    
    console.log('Table columns:');
    schemaCheck.rows.forEach(row => {
      console.log(`   - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });

    // Test 3: Test the exact query from backend
    console.log('\n4️⃣ Testing exact backend query...');
    const exactQuery = `
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
      ORDER BY er.emergency_date DESC
    `;
    
    try {
      const result = await client.query(exactQuery);
      console.log('✅ Query executed successfully!');
      console.log(`   Records found: ${result.rows.length}`);
      
      if (result.rows.length > 0) {
        console.log('   Sample record:');
        console.log('   ', JSON.stringify(result.rows[0], null, 2));
      }
      
    } catch (error) {
      console.log('❌ Query failed:');
      console.log('   Error:', error.message);
      console.log('   Code:', error.code);
      
      if (error.message.includes('column') && error.message.includes('does not exist')) {
        console.log('\n🔧 This confirms the database schema fix is not working.');
        console.log('The missing columns are still causing issues.');
      }
    }

    // Test 4: Check if there are any records
    console.log('\n5️⃣ Checking for existing records...');
    const countResult = await client.query('SELECT COUNT(*) as count FROM emergency_records');
    console.log(`   Total records: ${countResult.rows[0].count}`);

    client.release();
    console.log('\n🎉 Database test completed!');

  } catch (error) {
    console.log('❌ Database test failed:', error.message);
  } finally {
    await pool.end();
  }
}

console.log('📋 This script will test the exact emergency query that\'s failing.');
console.log('Make sure you have set the DATABASE_URL environment variable.\n');

testEmergencyQuery().catch(console.error); 