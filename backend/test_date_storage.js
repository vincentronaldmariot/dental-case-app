const { query } = require('./config/database');

async function testDateStorage() {
  try {
    console.log('🔍 Testing date storage and retrieval...');
    
    // Test 1: Check current timezone settings
    console.log('\n📋 Test 1: Check timezone settings');
    const timezoneResult = await query('SHOW timezone');
    console.log('Database timezone:', timezoneResult.rows[0].TimeZone);
    
    const currentTimeResult = await query('SELECT CURRENT_TIMESTAMP, CURRENT_DATE');
    console.log('Current timestamp:', currentTimeResult.rows[0].current_timestamp);
    console.log('Current date:', currentTimeResult.rows[0].current_date);
    
    // Test 2: Get an existing patient ID or create a test patient
    console.log('\n📋 Test 2: Get existing patient');
    const patientResult = await query('SELECT id FROM patients LIMIT 1');
    let testPatientId;
    
    if (patientResult.rows.length > 0) {
      testPatientId = patientResult.rows[0].id;
      console.log('Using existing patient ID:', testPatientId);
    } else {
      // Create a test patient if none exists
      const createPatientResult = await query(`
        INSERT INTO patients (first_name, last_name, email, phone, classification)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING id
      `, ['Test', 'Patient', 'test@example.com', '1234567890', 'Active Duty']);
      
      testPatientId = createPatientResult.rows[0].id;
      console.log('Created test patient ID:', testPatientId);
    }
    
    // Test 3: Insert a test appointment with a specific date
    console.log('\n📋 Test 3: Insert test appointment');
    const testDate = '2025-07-25';
    
    console.log('Inserting date:', testDate);
    
    const insertResult = await query(`
      INSERT INTO appointments (patient_id, service, appointment_date, time_slot, doctor_name, status)
      VALUES ($1, 'Test Service', $2::date, '10:00', 'Dr. Test', 'pending')
      RETURNING id, appointment_date
    `, [testPatientId, testDate]);
    
    const appointmentId = insertResult.rows[0].id;
    console.log('Inserted appointment ID:', appointmentId);
    console.log('Stored appointment_date:', insertResult.rows[0].appointment_date);
    console.log('Stored appointment_date type:', typeof insertResult.rows[0].appointment_date);
    console.log('Stored appointment_date constructor:', insertResult.rows[0].appointment_date.constructor.name);
    console.log('Stored appointment_date ISO:', insertResult.rows[0].appointment_date.toISOString());
    console.log('Stored appointment_date date part:', insertResult.rows[0].appointment_date.toISOString().split('T')[0]);
    
    // Test 4: Retrieve the appointment and see how it's formatted
    console.log('\n📋 Test 4: Retrieve appointment');
    const retrieveResult = await query(`
      SELECT id, appointment_date FROM appointments WHERE id = $1
    `, [appointmentId]);
    
    const retrievedDate = retrieveResult.rows[0].appointment_date;
    console.log('Retrieved appointment_date:', retrievedDate);
    console.log('Retrieved appointment_date ISO:', retrievedDate.toISOString());
    console.log('Retrieved appointment_date date part:', retrievedDate.toISOString().split('T')[0]);
    
    // Test 5: Test the pending appointments query
    console.log('\n📋 Test 5: Test pending appointments query');
    const pendingResult = await query(`
      SELECT 
        a.id AS appointment_id,
        a.service,
        a.appointment_date AS booking_date,
        a.time_slot,
        a.status
      FROM appointments a
      WHERE a.id = $1
    `, [appointmentId]);
    
    const pendingAppointment = pendingResult.rows[0];
    console.log('Pending appointment booking_date:', pendingAppointment.booking_date);
    console.log('Pending appointment booking_date ISO:', pendingAppointment.booking_date.toISOString());
    console.log('Pending appointment booking_date date part:', pendingAppointment.booking_date.toISOString().split('T')[0]);
    
    // Test 6: Test different date insertion methods
    console.log('\n📋 Test 6: Test different date insertion methods');
    
    const testDates = [
      '2025-07-25',
      '2025-07-25T00:00:00.000Z',
      '2025-07-25T00:00:00.000+08:00'
    ];
    
    for (const testDate of testDates) {
      console.log(`\nTesting date: ${testDate}`);
      
      const testInsertResult = await query(`
        INSERT INTO appointments (patient_id, service, appointment_date, time_slot, doctor_name, status)
        VALUES ($1, 'Test Service', $2::date, '10:00', 'Dr. Test', 'pending')
        RETURNING appointment_date
      `, [testPatientId, testDate]);
      
      const storedDate = testInsertResult.rows[0].appointment_date;
      console.log(`  Stored: ${storedDate}`);
      console.log(`  ISO: ${storedDate.toISOString()}`);
      console.log(`  Date part: ${storedDate.toISOString().split('T')[0]}`);
    }
    
    // Clean up test data
    await query('DELETE FROM appointments WHERE patient_id = $1', [testPatientId]);
    console.log('\n✅ Date storage test completed successfully!');
    
  } catch (error) {
    console.error('❌ Error in date storage test:', error);
  }
}

testDateStorage(); 