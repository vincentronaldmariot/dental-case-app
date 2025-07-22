const { query } = require('./config/database');

async function testAppointmentDateEdit() {
  try {
    console.log('🔍 Testing appointment date editing...');
    
    // Test 1: Create a test appointment
    console.log('\n📋 Test 1: Create test appointment');
    const testPatientId = '123e4567-e89b-12d3-a456-426614174000';
    const originalDate = '2025-01-15';
    
    const insertResult = await query(`
      INSERT INTO appointments (patient_id, service, appointment_date, time_slot, status)
      VALUES ($1, 'Test Service', $2::date, '10:00', 'pending')
      RETURNING id, appointment_date
    `, [testPatientId, originalDate]);
    
    const appointmentId = insertResult.rows[0].id;
    console.log('Created appointment ID:', appointmentId);
    console.log('Original date:', insertResult.rows[0].appointment_date);
    console.log('Original date ISO:', insertResult.rows[0].appointment_date.toISOString());
    
    // Test 2: Update the appointment date
    console.log('\n📋 Test 2: Update appointment date');
    const newDate = '2025-01-20';
    
    const updateResult = await query(`
      UPDATE appointments 
      SET appointment_date = $1::date, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING id, appointment_date, updated_at
    `, [newDate, appointmentId]);
    
    console.log('Updated appointment:');
    console.log('  ID:', updateResult.rows[0].id);
    console.log('  New date:', updateResult.rows[0].appointment_date);
    console.log('  New date ISO:', updateResult.rows[0].appointment_date.toISOString());
    console.log('  Updated at:', updateResult.rows[0].updated_at);
    
    // Test 3: Verify the date is correct
    console.log('\n📋 Test 3: Verify date is correct');
    const verifyResult = await query(`
      SELECT id, appointment_date FROM appointments WHERE id = $1
    `, [appointmentId]);
    
    const storedDate = verifyResult.rows[0].appointment_date;
    console.log('Stored date:', storedDate);
    console.log('Stored date ISO:', storedDate.toISOString());
    console.log('Date part only:', storedDate.toISOString().split('T')[0]);
    
    // Test 4: Test different date formats
    console.log('\n📋 Test 4: Test different date formats');
    const testDates = [
      '2025-01-25',
      '2025-02-01',
      '2025-03-15'
    ];
    
    for (const testDate of testDates) {
      console.log(`\nTesting date: ${testDate}`);
      
      const testUpdateResult = await query(`
        UPDATE appointments 
        SET appointment_date = $1::date, updated_at = CURRENT_TIMESTAMP
        WHERE id = $2
        RETURNING appointment_date
      `, [testDate, appointmentId]);
      
      const resultDate = testUpdateResult.rows[0].appointment_date;
      console.log(`  Result: ${resultDate}`);
      console.log(`  ISO: ${resultDate.toISOString()}`);
      console.log(`  Date part: ${resultDate.toISOString().split('T')[0]}`);
      console.log(`  Expected: ${testDate}`);
      console.log(`  Match: ${resultDate.toISOString().split('T')[0] === testDate ? '✅' : '❌'}`);
    }
    
    // Test 5: Test admin update endpoint simulation
    console.log('\n📋 Test 5: Test admin update endpoint simulation');
    const adminUpdateDate = '2025-04-10';
    
    const adminUpdateResult = await query(`
      UPDATE appointments 
      SET appointment_date = $1::date, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING id, appointment_date, time_slot, service, updated_at
    `, [adminUpdateDate, appointmentId]);
    
    const adminUpdatedAppointment = adminUpdateResult.rows[0];
    console.log('Admin update result:');
    console.log('  ID:', adminUpdatedAppointment.id);
    console.log('  Date:', adminUpdatedAppointment.appointment_date);
    console.log('  Date ISO:', adminUpdatedAppointment.appointment_date.toISOString());
    console.log('  Date part:', adminUpdatedAppointment.appointment_date.toISOString().split('T')[0]);
    console.log('  Expected:', adminUpdateDate);
    console.log('  Match:', adminUpdatedAppointment.appointment_date.toISOString().split('T')[0] === adminUpdateDate ? '✅' : '❌');
    
    // Clean up test data
    await query('DELETE FROM appointments WHERE id = $1', [appointmentId]);
    console.log('\n✅ Appointment date editing test completed successfully!');
    
  } catch (error) {
    console.error('❌ Error in appointment date editing test:', error);
  }
}

testAppointmentDateEdit(); 