const { Pool } = require('pg');

async function testDirectDatabaseConnection() {
  console.log('🔍 Testing Direct Database Connection...\n');

  // Connection details from Railway
  const dbConfig = {
    host: 'ballast.proxy.rlwy.net',
    port: 27199,
    database: 'railway',
    user: 'postgres',
    password: 'glfJbkmkHHAAlKQqFzNtkMQjXOPjJthr',
    ssl: false, // Disable SSL for testing
    max: 5,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 60000
  };

  console.log('📋 Connection config:', {
    host: dbConfig.host,
    port: dbConfig.port,
    database: dbConfig.database,
    user: dbConfig.user,
    ssl: dbConfig.ssl ? 'enabled' : 'disabled'
  });

  let pool = null;
  try {
    // Create connection pool
    pool = new Pool(dbConfig);
    console.log('✅ Pool created successfully');

    // Test connection
    const client = await pool.connect();
    console.log('✅ Connected to database successfully');

    // Test basic query
    const result = await client.query('SELECT NOW() as current_time');
    console.log('✅ Query executed successfully');
    console.log('🕒 Database time:', result.rows[0].current_time);

    // Test if tables exist
    const tablesResult = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    console.log('📋 Available tables:', tablesResult.rows.map(row => row.table_name));

    // Test specific tables that admin dashboard needs
    const requiredTables = ['patients', 'appointments', 'dental_surveys', 'emergency_records'];
    
    for (const table of requiredTables) {
      try {
        const countResult = await client.query(`SELECT COUNT(*) as count FROM ${table}`);
        console.log(`✅ ${table} table exists with ${countResult.rows[0].count} records`);
      } catch (error) {
        console.log(`❌ ${table} table error:`, error.message);
      }
    }

    // Test admin dashboard queries
    console.log('\n🧪 Testing admin dashboard queries...');

    try {
      const patientsCount = await client.query('SELECT COUNT(*) as count FROM patients');
      console.log('✅ Patients count query:', patientsCount.rows[0].count);
    } catch (error) {
      console.log('❌ Patients count query failed:', error.message);
    }

    try {
      const appointmentsCount = await client.query('SELECT COUNT(*) as count FROM appointments');
      console.log('✅ Appointments count query:', appointmentsCount.rows[0].count);
    } catch (error) {
      console.log('❌ Appointments count query failed:', error.message);
    }

    try {
      const surveysCount = await client.query('SELECT COUNT(*) as count FROM dental_surveys');
      console.log('✅ Surveys count query:', surveysCount.rows[0].count);
    } catch (error) {
      console.log('❌ Surveys count query failed:', error.message);
    }

    try {
      const emergenciesCount = await client.query('SELECT COUNT(*) as count FROM emergency_records');
      console.log('✅ Emergency records count query:', emergenciesCount.rows[0].count);
    } catch (error) {
      console.log('❌ Emergency records count query failed:', error.message);
    }

    client.release();
    console.log('\n🎉 Database connection test completed successfully!');

  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    console.error('Error details:', error);
  } finally {
    if (pool) {
      await pool.end();
      console.log('🔌 Pool closed');
    }
  }
}

testDirectDatabaseConnection(); 