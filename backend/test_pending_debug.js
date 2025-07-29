const { Pool } = require('pg');

// Use in-memory database configuration
const pool = new Pool({
  host: 'localhost',
  port: 5432,
  database: 'dental_case_db',
  user: 'postgres',
  password: 'password',
  ssl: false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

async function testPendingAppointmentsQuery() {
  console.log('🔧 Testing pending appointments query step by step...\n');
  
  try {
    // 1. Check if appointments table exists and has data
    console.log('1. Checking appointments table...');
    const appointmentsResult = await pool.query('SELECT COUNT(*) FROM appointments');
    console.log(`   Appointments count: ${appointmentsResult.rows[0]?.count || 0}`);
    
    // 2. Check if patients table exists and has data
    console.log('\n2. Checking patients table...');
    const patientsResult = await pool.query('SELECT COUNT(*) FROM patients');
    console.log(`   Patients count: ${patientsResult.rows[0]?.count || 0}`);
    
    // 3. Check if dental_surveys table exists and has data
    console.log('\n3. Checking dental_surveys table...');
    const surveysResult = await pool.query('SELECT COUNT(*) FROM dental_surveys');
    console.log(`   Surveys count: ${surveysResult.rows[0]?.count || 0}`);
    
    // 4. Check pending appointments specifically
    console.log('\n4. Checking pending appointments...');
    const pendingResult = await pool.query("SELECT COUNT(*) FROM appointments WHERE status = 'pending'");
    console.log(`   Pending appointments count: ${pendingResult.rows[0]?.count || 0}`);
    
    // 5. Try the full query
    console.log('\n5. Testing the full pending appointments query...');
    const fullQueryResult = await pool.query(`
      SELECT 
        a.id AS appointment_id,
        a.service,
        a.appointment_date AS booking_date,
        a.time_slot,
        a.status,
        p.first_name, p.last_name, p.email,
        p.phone,
        p.classification,
        p.unit_assignment,
        p.serial_number,
        s.survey_data
      FROM appointments a
      JOIN patients p ON a.patient_id = p.id
      LEFT JOIN dental_surveys s ON s.patient_id = p.id
      WHERE a.status = 'pending'
      ORDER BY a.appointment_date ASC
    `);
    
    console.log(`   Full query returned ${fullQueryResult.rows.length} rows`);
    if (fullQueryResult.rows.length > 0) {
      console.log('   First row:', fullQueryResult.rows[0]);
    }
    
    console.log('\n✅ Query test completed successfully!');
    
  } catch (error) {
    console.log('❌ Error during query test:', error.message);
    console.log('Error details:', error);
  } finally {
    await pool.end();
  }
}

testPendingAppointmentsQuery();