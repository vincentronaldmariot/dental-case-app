const { query } = require('./config/database');

async function removePatientsExceptViperson1() {
  try {
    console.log('🔍 Starting patient cleanup process...');
    
    // First, let's see what patients exist
    const allPatients = await query('SELECT id, email, first_name, last_name FROM patients ORDER BY created_at');
    console.log(`📊 Found ${allPatients.rows.length} total patients:`);
    
    allPatients.rows.forEach(patient => {
      console.log(`   - ${patient.email} (${patient.first_name} ${patient.last_name})`);
    });
    
    // Find the viperson1@gmail.com patient
    const viperson1Patient = await query('SELECT id, email, first_name, last_name FROM patients WHERE email = $1', ['viperson1@gmail.com']);
    
    if (viperson1Patient.rows.length === 0) {
      console.log('❌ viperson1@gmail.com not found in database!');
      return;
    }
    
    const keepPatient = viperson1Patient.rows[0];
    console.log(`✅ Found patient to keep: ${keepPatient.email} (${keepPatient.first_name} ${keepPatient.last_name})`);
    
    // Get patients to delete (all except viperson1@gmail.com)
    const patientsToDelete = allPatients.rows.filter(p => p.email !== 'viperson1@gmail.com');
    
    if (patientsToDelete.length === 0) {
      console.log('✅ No patients to delete - only viperson1@gmail.com exists');
      return;
    }
    
    console.log(`🗑️ Will delete ${patientsToDelete.length} patients:`);
    patientsToDelete.forEach(patient => {
      console.log(`   - ${patient.email} (${patient.first_name} ${patient.last_name})`);
    });
    
    // Start transaction
    const client = await query('BEGIN');
    
    try {
      // Delete related records first (in order of dependencies)
      
      // 1. Delete notifications for patients to be deleted
      const patientIdsToDelete = patientsToDelete.map(p => p.id);
      const deleteNotifications = await query(
        'DELETE FROM notifications WHERE patient_id = ANY($1)',
        [patientIdsToDelete]
      );
      console.log(`🗑️ Deleted ${deleteNotifications.rowCount} notifications`);
      
      // 2. Delete emergency records for patients to be deleted
      const deleteEmergencyRecords = await query(
        'DELETE FROM emergency_records WHERE patient_id = ANY($1)',
        [patientIdsToDelete]
      );
      console.log(`🗑️ Deleted ${deleteEmergencyRecords.rowCount} emergency records`);
      
      // 3. Delete dental surveys for patients to be deleted
      const deleteSurveys = await query(
        'DELETE FROM dental_surveys WHERE patient_id = ANY($1)',
        [patientIdsToDelete]
      );
      console.log(`🗑️ Deleted ${deleteSurveys.rowCount} dental surveys`);
      
      // 4. Delete patient notes for patients to be deleted
      const deleteNotes = await query(
        'DELETE FROM patient_notes WHERE patient_id = ANY($1)',
        [patientIdsToDelete]
      );
      console.log(`🗑️ Deleted ${deleteNotes.rowCount} patient notes`);
      
      // 5. Delete appointments for patients to be deleted
      const deleteAppointments = await query(
        'DELETE FROM appointments WHERE patient_id = ANY($1)',
        [patientIdsToDelete]
      );
      console.log(`🗑️ Deleted ${deleteAppointments.rowCount} appointments`);
      
      // 6. Finally, delete the patients themselves
      const deletePatients = await query(
        'DELETE FROM patients WHERE id = ANY($1)',
        [patientIdsToDelete]
      );
      console.log(`🗑️ Deleted ${deletePatients.rowCount} patients`);
      
      // Commit transaction
      await query('COMMIT');
      console.log('✅ Transaction committed successfully');
      
      // Verify the result
      const remainingPatients = await query('SELECT id, email, first_name, last_name FROM patients ORDER BY created_at');
      console.log(`\n📊 After cleanup: ${remainingPatients.rows.length} patients remain:`);
      
      remainingPatients.rows.forEach(patient => {
        console.log(`   - ${patient.email} (${patient.first_name} ${patient.last_name})`);
      });
      
      if (remainingPatients.rows.length === 1 && remainingPatients.rows[0].email === 'viperson1@gmail.com') {
        console.log('✅ Success! Only viperson1@gmail.com remains in the database.');
      } else {
        console.log('⚠️ Warning: Unexpected patients remain in database');
      }
      
    } catch (error) {
      // Rollback transaction on error
      await query('ROLLBACK');
      console.error('❌ Error during deletion, transaction rolled back:', error);
      throw error;
    }
    
  } catch (error) {
    console.error('❌ Failed to remove patients:', error);
    throw error;
  }
}

// Run the script
if (require.main === module) {
  removePatientsExceptViperson1()
    .then(() => {
      console.log('✅ Patient cleanup completed successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Patient cleanup failed:', error);
      process.exit(1);
    });
}

module.exports = { removePatientsExceptViperson1 }; 