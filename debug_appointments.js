const mysql = require('mysql2/promise');

// Database configuration
const dbConfig = {
  host: 'localhost',
  user: 'root',
  password: '',
  database: 'dental_clinic'
};

async function debugAppointments() {
  let connection;
  
  try {
    console.log('🔍 === APPOINTMENT DEBUG ANALYSIS ===');
    console.log('Time:', new Date().toISOString());
    console.log('');

    // Connect to database
    connection = await mysql.createConnection(dbConfig);
    console.log('✅ Connected to database');
    console.log('');

    // Get all appointments
    const [appointments] = await connection.execute(`
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

    console.log(`📊 Total appointments in database: ${appointments.length}`);
    console.log('');

    if (appointments.length > 0) {
      console.log('📋 All Appointments:');
      for (let i = 0; i < appointments.length; i++) {
        const apt = appointments[i];
        console.log(`   ${i}: ID="${apt.id}", PatientID="${apt.patient_id}", Service="${apt.service}", Status="${apt.status}", Date="${apt.appointment_date}"`);
      }
      console.log('');
    }

    // Count appointments by status
    const statusCounts = {};
    appointments.forEach(apt => {
      const status = apt.status || 'unknown';
      statusCounts[status] = (statusCounts[status] || 0) + 1;
    });

    console.log('📈 Status Breakdown:');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`   Status "${status}": ${count} appointments`);
    });
    console.log('');

    // Check for pending appointments
    const pendingAppointments = appointments.filter(apt => 
      apt.status && apt.status.toLowerCase() === 'pending'
    );

    console.log(`⏳ Pending appointments: ${pendingAppointments.length}`);
    console.log(`pendingAppointments.length > 0: ${pendingAppointments.length > 0}`);
    console.log('');

    if (pendingAppointments.length > 0) {
      console.log('📋 Pending Appointments Details:');
      for (let i = 0; i < pendingAppointments.length; i++) {
        const apt = pendingAppointments[i];
        console.log(`   ${i}: ID="${apt.id}", PatientID="${apt.patient_id}", Service="${apt.service}", Status="${apt.status}", Date="${apt.appointment_date}"`);
      }
      console.log('');
    }

    // Check for problematic appointments
    const problematicAppointments = appointments.filter(apt => 
      !apt.id || apt.id.trim() === '' || 
      !apt.service || apt.service.trim() === '' || 
      !apt.patient_id || apt.patient_id.trim() === ''
    );

    if (problematicAppointments.length > 0) {
      console.log('⚠️ Problematic Appointments (empty values):');
      for (const apt of problematicAppointments) {
        console.log(`   - ID: "${apt.id}", PatientID: "${apt.patient_id}", Service: "${apt.service}", Status: "${apt.status}"`);
      }
      console.log('');
    }

    // Check for appointments with unknown status
    const unknownStatusAppointments = appointments.filter(apt => 
      !apt.status || apt.status.trim() === ''
    );

    if (unknownStatusAppointments.length > 0) {
      console.log('⚠️ Appointments with Unknown/Empty Status:');
      for (const apt of unknownStatusAppointments) {
        console.log(`   - ID: "${apt.id}", PatientID: "${apt.patient_id}", Service: "${apt.service}", Status: "${apt.status}"`);
      }
      console.log('');
    }

    // Get recent appointments (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const recentAppointments = appointments.filter(apt => 
      new Date(apt.created_at) > sevenDaysAgo
    );

    console.log(`📅 Recent appointments (last 7 days): ${recentAppointments.length}`);
    if (recentAppointments.length > 0) {
      console.log('📋 Recent Appointments:');
      for (const apt of recentAppointments) {
        console.log(`   - ID: "${apt.id}", PatientID: "${apt.patient_id}", Service: "${apt.service}", Status: "${apt.status}", Created: "${apt.created_at}"`);
      }
      console.log('');
    }

    // Check if there are any test appointments
    const testAppointments = appointments.filter(apt => 
      apt.service && apt.service.toLowerCase().includes('test') ||
      apt.notes && apt.notes.toLowerCase().includes('test')
    );

    if (testAppointments.length > 0) {
      console.log('🧪 Test Appointments:');
      for (const apt of testAppointments) {
        console.log(`   - ID: "${apt.id}", PatientID: "${apt.patient_id}", Service: "${apt.service}", Status: "${apt.status}", Notes: "${apt.notes}"`);
      }
      console.log('');
    }

    console.log('=== END DEBUG ANALYSIS ===');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    if (connection) {
      await connection.end();
      console.log('✅ Database connection closed');
    }
  }
}

// Run the debug function
debugAppointments(); 