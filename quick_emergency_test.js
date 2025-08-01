const { Pool } = require('pg');

// Enhanced SSL configuration for Railway
const getSSLConfig = () => {
  if (process.env.NODE_ENV !== 'production') {
    return false;
  }
  
  return {
    rejectUnauthorized: false
  };
};

// Use DATABASE_PUBLIC_URL if available (for external connections), otherwise use DATABASE_URL
const dbConfig = (process.env.DATABASE_PUBLIC_URL || process.env.DATABASE_URL) ? {
  connectionString: process.env.DATABASE_PUBLIC_URL || process.env.DATABASE_URL,
  ssl: getSSLConfig(),
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 30000,
  query_timeout: 30000,
  statement_timeout: 30000
} : {
  host: process.env.PGHOST || process.env.DB_HOST || 'localhost',
  port: process.env.PGPORT || process.env.DB_PORT || 5432,
  database: process.env.PGDATABASE || process.env.DB_NAME || 'dental_case_db',
  user: process.env.PGUSER || process.env.DB_USER || 'dental_user',
  password: process.env.PGPASSWORD || process.env.DB_PASSWORD || 'dental_password',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 30000,
  ssl: getSSLConfig(),
};

const pool = new Pool(dbConfig);

async function quickEmergencyTest() {
  try {
    console.log('🔍 Quick Emergency Database Test\n');
    
    const client = await pool.connect();
    console.log('✅ Connected to database');
    
    // Test the exact query from the admin route
    console.log('📋 Testing emergency records query...');
    const result = await client.query(`
      SELECT 
        er.id, er.patient_id, 
        TO_CHAR(er.reported_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as reported_at, 
        er.emergency_type, er.priority, 
        er.status, er.description, er.pain_level, er.symptoms, er.location,
        er.duty_related, er.unit_command, er.handled_by, er.first_aid_provided,
        CASE WHEN er.resolved_at IS NOT NULL 
          THEN TO_CHAR(er.resolved_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
          ELSE NULL 
        END as resolved_at, 
        er.resolution, er.follow_up_required, er.emergency_contact,
        er.notes, 
        TO_CHAR(er.created_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at, 
        TO_CHAR(er.updated_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as updated_at,
        p.first_name, p.last_name, p.email, p.phone
      FROM emergency_records er
      LEFT JOIN patients p ON er.patient_id = p.id
      ORDER BY er.reported_at DESC
    `);
    
    console.log('✅ Query executed successfully');
    console.log(`📊 Found ${result.rows.length} emergency records`);
    
    if (result.rows.length > 0) {
      const record = result.rows[0];
      console.log('📋 Sample record:');
      console.log(`   - ID: ${record.id} (type: ${typeof record.id})`);
      console.log(`   - Patient ID: ${record.patient_id}`);
      console.log(`   - Status: ${record.status}`);
      console.log(`   - Priority: ${record.priority}`);
      console.log(`   - Emergency Type: ${record.emergency_type}`);
      console.log(`   - Pain Level: ${record.pain_level}`);
      console.log(`   - Patient Name: ${record.first_name} ${record.last_name}`);
    }
    
    client.release();
    console.log('\n🎉 Database test completed successfully!');
    
  } catch (error) {
    console.error('❌ Database test failed:', error);
  } finally {
    await pool.end();
  }
}

quickEmergencyTest(); 