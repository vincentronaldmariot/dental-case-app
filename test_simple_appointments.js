const { query } = require('./backend/config/database');

async function testSimpleAppointments() {
  try {
    console.log('🧪 Testing simple appointments query...');
    
    const patientId = 'fec7baf7-c9c1-4dd6-a5bb-9fde3b286d6e'; // viperson1@gmail.com
    
    console.log('🔍 Testing appointments query for patient:', patientId);
    
    const appointmentsResult = await query(`
      SELECT id, service, appointment_date, time_slot, status, notes, created_at
      FROM appointments 
      WHERE patient_id = $1
      ORDER BY appointment_date DESC
      LIMIT 20
    `, [patientId]);
    
    console.log('✅ Appointments query successful');
    console.log('📊 Appointments found:', appointmentsResult.rows.length);
    
    appointmentsResult.rows.forEach((apt, index) => {
      console.log(`  Appointment ${index + 1}:`);
      console.log(`    - ID: ${apt.id}`);
      console.log(`    - Service: ${apt.service}`);
      console.log(`    - Date: ${apt.appointment_date}`);
      console.log(`    - Time: ${apt.time_slot}`);
      console.log(`    - Status: ${apt.status}`);
    });
    
  } catch (error) {
    console.error('❌ Error testing appointments query:', error);
    console.error('❌ Error stack:', error.stack);
  }
}

testSimpleAppointments(); 