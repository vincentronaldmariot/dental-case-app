const { query } = require('./config/database');

async function createTestAppointment() {
  try {
    console.log('Creating test appointment...');
    
    // Get a patient ID
    const patientResult = await query('SELECT id FROM patients LIMIT 1');
    if (patientResult.rows.length === 0) {
      console.log('❌ No patients found');
      return;
    }
    
    const patientId = patientResult.rows[0].id;
    console.log(`Using patient ID: ${patientId}`);
    
    // Create a test appointment
    const appointmentResult = await query(`
      INSERT INTO appointments (
        patient_id, service, appointment_date, time_slot, 
        status, notes, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      ) RETURNING id, service, appointment_date, status
    `, [
      patientId,
      'Test Service',
      '2025-07-20T10:00:00.000Z',
      '10:00 AM',
      'pending',
      'Test appointment for notification testing'
    ]);
    
    console.log('✅ Test appointment created:');
    console.log(JSON.stringify(appointmentResult.rows[0], null, 2));
    
    // Check pending appointments count
    const pendingResult = await query("SELECT COUNT(*) as count FROM appointments WHERE status = 'pending'");
    console.log(`Total pending appointments: ${pendingResult.rows[0].count}`);
    
  } catch (error) {
    console.error('❌ Error creating appointment:', error);
  }
}

createTestAppointment(); 