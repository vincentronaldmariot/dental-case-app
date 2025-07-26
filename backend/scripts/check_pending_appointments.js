const { query } = require('../config/database');

async function checkPendingAppointments() {
  try {
    console.log('🔍 Checking pending appointments in database...');
    
    // Get all pending appointments
    const pendingResult = await query(`
      SELECT id, patient_id, service, appointment_date, time_slot, status, notes, created_at
      FROM appointments 
      WHERE status = 'pending'
      ORDER BY created_at DESC
    `);
    
    console.log(`📊 Total pending appointments: ${pendingResult.rows.length}`);
    
    // Group by patient
    const appointmentsByPatient = {};
    pendingResult.rows.forEach(apt => {
      const patientId = apt.patient_id;
      if (!appointmentsByPatient[patientId]) {
        appointmentsByPatient[patientId] = [];
      }
      appointmentsByPatient[patientId].push(apt);
    });
    
    console.log('\n👥 Pending appointments by patient:');
    Object.keys(appointmentsByPatient).forEach(patientId => {
      const appointments = appointmentsByPatient[patientId];
      console.log(`\nPatient ${patientId}: ${appointments.length} pending appointments`);
      appointments.forEach(apt => {
        console.log(`  - ID: ${apt.id}, Service: ${apt.service}, Date: ${apt.appointment_date}, Time: ${apt.time_slot}`);
      });
    });
    
    // Get all appointments for comparison
    const allResult = await query(`
      SELECT id, patient_id, service, appointment_date, time_slot, status, notes, created_at
      FROM appointments 
      ORDER BY created_at DESC
    `);
    
    console.log(`\n📈 Total appointments in database: ${allResult.rows.length}`);
    
    // Group all appointments by patient
    const allByPatient = {};
    allResult.rows.forEach(apt => {
      const patientId = apt.patient_id;
      if (!allByPatient[patientId]) {
        allByPatient[patientId] = [];
      }
      allByPatient[patientId].push(apt);
    });
    
    console.log('\n👥 All appointments by patient:');
    Object.keys(allByPatient).forEach(patientId => {
      const appointments = allByPatient[patientId];
      const pendingCount = appointments.filter(apt => apt.status === 'pending').length;
      const completedCount = appointments.filter(apt => apt.status === 'completed').length;
      const cancelledCount = appointments.filter(apt => apt.status === 'cancelled').length;
      const otherCount = appointments.length - pendingCount - completedCount - cancelledCount;
      
      console.log(`\nPatient ${patientId}: ${appointments.length} total appointments`);
      console.log(`  - Pending: ${pendingCount}`);
      console.log(`  - Completed: ${completedCount}`);
      console.log(`  - Cancelled: ${cancelledCount}`);
      console.log(`  - Other: ${otherCount}`);
    });
    
  } catch (error) {
    console.error('❌ Error checking appointments:', error);
  } finally {
    process.exit(0);
  }
}

checkPendingAppointments(); 