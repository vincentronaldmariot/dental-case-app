const { query } = require('./backend/config/database');

async function checkPatientAppointments() {
  try {
    console.log('🔍 Checking patient appointments...');
    
    // Check appointments for john.doe@test.com
    const johnDoeResult = await query(`
      SELECT p.id, p.first_name, p.last_name, p.email,
             COUNT(a.id) as appointment_count
      FROM patients p
      LEFT JOIN appointments a ON p.id = a.patient_id
      WHERE p.email = 'john.doe@test.com'
      GROUP BY p.id, p.first_name, p.last_name, p.email
    `);
    
    if (johnDoeResult.rows.length > 0) {
      const patient = johnDoeResult.rows[0];
      console.log(`👤 Patient: ${patient.first_name} ${patient.last_name} (${patient.email})`);
      console.log(`📊 Appointments: ${patient.appointment_count}`);
    } else {
      console.log('❌ john.doe@test.com not found');
    }
    
    // Find patients with appointments
    console.log('\n🔍 Finding patients with appointments...');
    const patientsWithAppointments = await query(`
      SELECT p.id, p.first_name, p.last_name, p.email,
             COUNT(a.id) as appointment_count
      FROM patients p
      INNER JOIN appointments a ON p.id = a.patient_id
      GROUP BY p.id, p.first_name, p.last_name, p.email
      ORDER BY appointment_count DESC
    `);
    
    console.log('📊 Patients with appointments:');
    patientsWithAppointments.rows.forEach((patient, index) => {
      console.log(`  ${index + 1}. ${patient.first_name} ${patient.last_name} (${patient.email}) - ${patient.appointment_count} appointments`);
    });
    
    // Show sample appointments
    if (patientsWithAppointments.rows.length > 0) {
      const firstPatient = patientsWithAppointments.rows[0];
      console.log(`\n🔍 Sample appointments for ${firstPatient.first_name} ${firstPatient.last_name}:`);
      
      const appointmentsResult = await query(`
        SELECT id, service, appointment_date, time_slot, status, notes
        FROM appointments 
        WHERE patient_id = $1
        ORDER BY appointment_date DESC
        LIMIT 3
      `, [firstPatient.id]);
      
      appointmentsResult.rows.forEach((apt, index) => {
        console.log(`  Appointment ${index + 1}:`);
        console.log(`    - Service: ${apt.service}`);
        console.log(`    - Date: ${apt.appointment_date}`);
        console.log(`    - Time: ${apt.time_slot}`);
        console.log(`    - Status: ${apt.status}`);
        console.log(`    - Notes: ${apt.notes || 'None'}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Error checking patient appointments:', error);
  }
}

checkPatientAppointments(); 