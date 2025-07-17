const { query } = require('./config/database');

async function checkAppointments() {
  try {
    console.log('Checking appointments in database...');
    
    // Check total appointments
    const totalResult = await query('SELECT COUNT(*) as count FROM appointments');
    console.log('Total appointments:', totalResult.rows[0].count);
    
    // Check pending appointments
    const pendingResult = await query("SELECT COUNT(*) as count FROM appointments WHERE status = 'pending'");
    console.log('Pending appointments:', pendingResult.rows[0].count);
    
    // Check all appointments with details
    const allResult = await query(`
      SELECT id, patient_id, service, appointment_date, time_slot, status, created_at 
      FROM appointments 
      ORDER BY created_at DESC 
      LIMIT 10
    `);
    
    console.log('\nRecent appointments:');
    allResult.rows.forEach((row, index) => {
      console.log(`${index + 1}. ID: ${row.id}, Patient: ${row.patient_id}, Service: ${row.service}, Date: ${row.appointment_date}, Status: ${row.status}`);
    });
    
  } catch (error) {
    console.error('Error checking appointments:', error);
  } finally {
    process.exit();
  }
}

checkAppointments(); 