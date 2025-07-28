const { query } = require('./config/database');

async function debugAllAppointments() {
  try {
    console.log('🔍 === COMPREHENSIVE APPOINTMENT DEBUG ===');
    console.log('Time:', new Date().toISOString());
    console.log('');

    // Get all appointments with all details
    const allResult = await query(`
      SELECT 
        id, 
        patient_id, 
        service, 
        appointment_date, 
        time_slot, 
        status, 
        notes,
        created_at,
        updated_at
      FROM appointments 
      ORDER BY created_at DESC
    `);

    console.log(`📊 Total appointments in database: ${allResult.rows.length}`);
    console.log('');

    // Count by status
    const statusCounts = {};
    allResult.rows.forEach(row => {
      const status = row.status || 'unknown';
      statusCounts[status] = (statusCounts[status] || 0) + 1;
    });

    console.log('📈 Status Breakdown:');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`   Status "${status}": ${count} appointments`);
    });
    console.log('');

    // Check for pending appointments specifically
    const pendingAppointments = allResult.rows.filter(row => 
      row.status && row.status.toLowerCase() === 'pending'
    );

    console.log(`⏳ Pending appointments: ${pendingAppointments.length}`);
    console.log(`pendingAppointments.length > 0: ${pendingAppointments.length > 0}`);
    console.log('');

    if (pendingAppointments.length > 0) {
      console.log('📋 Pending Appointments Details:');
      pendingAppointments.forEach((apt, index) => {
        console.log(`   ${index + 1}: ID="${apt.id}", PatientID="${apt.patient_id}", Service="${apt.service}", Status="${apt.status}", Date="${apt.appointment_date}"`);
      });
      console.log('');
    }

    // Check for problematic appointments
    const problematicAppointments = allResult.rows.filter(row => 
      !row.id || row.id.trim() === '' || 
      !row.service || row.service.trim() === '' || 
      !row.patient_id || row.patient_id.trim() === ''
    );

    if (problematicAppointments.length > 0) {
      console.log('⚠️ Problematic Appointments (empty values):');
      problematicAppointments.forEach(apt => {
        console.log(`   - ID: "${apt.id}", PatientID: "${apt.patient_id}", Service: "${apt.service}", Status: "${apt.status}"`);
      });
      console.log('');
    }

    // Check for appointments with unknown status
    const unknownStatusAppointments = allResult.rows.filter(row => 
      !row.status || row.status.trim() === ''
    );

    if (unknownStatusAppointments.length > 0) {
      console.log('⚠️ Appointments with Unknown/Empty Status:');
      unknownStatusAppointments.forEach(apt => {
        console.log(`   - ID: "${apt.id}", PatientID: "${apt.patient_id}", Service: "${apt.service}", Status: "${apt.status}"`);
      });
      console.log('');
    }

    // Show recent appointments (last 10)
    console.log('📅 Recent appointments (last 10):');
    allResult.rows.slice(0, 10).forEach((apt, index) => {
      console.log(`   ${index + 1}: ID="${apt.id}", PatientID="${apt.patient_id}", Service="${apt.service}", Status="${apt.status}", Date="${apt.appointment_date}"`);
    });
    console.log('');

    // Check if there are any test appointments
    const testAppointments = allResult.rows.filter(row => 
      (row.service && row.service.toLowerCase().includes('test')) ||
      (row.notes && row.notes && row.notes.toLowerCase().includes('test'))
    );

    if (testAppointments.length > 0) {
      console.log('🧪 Test Appointments:');
      testAppointments.forEach(apt => {
        console.log(`   - ID: "${apt.id}", PatientID: "${apt.patient_id}", Service: "${apt.service}", Status: "${apt.status}", Notes: "${apt.notes}"`);
      });
      console.log('');
    }

    console.log('=== END DEBUG ANALYSIS ===');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit();
  }
}

debugAllAppointments(); 