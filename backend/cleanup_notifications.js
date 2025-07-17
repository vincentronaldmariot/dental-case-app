const { query } = require('./config/database');

async function cleanupNotifications() {
  try {
    console.log('🧹 Starting notification cleanup...');
    
    // Get all patients who have more than 20 notifications
    const patientsWithExcessNotifications = await query(`
      SELECT patient_id, COUNT(*) as notification_count
      FROM notifications
      GROUP BY patient_id
      HAVING COUNT(*) > 20
    `);
    
    console.log(`Found ${patientsWithExcessNotifications.rows.length} patients with excess notifications`);
    
    for (const patient of patientsWithExcessNotifications.rows) {
      const patientId = patient.patient_id;
      const currentCount = parseInt(patient.notification_count);
      const excessCount = currentCount - 20;
      
      console.log(`Patient ${patientId}: ${currentCount} notifications (${excessCount} excess)`);
      
      // Delete excess notifications (keep only the 20 most recent)
      const deleteResult = await query(`
        DELETE FROM notifications
        WHERE id IN (
          SELECT id FROM notifications
          WHERE patient_id = $1
          ORDER BY created_at DESC
          OFFSET 20
        )
      `, [patientId]);
      
      console.log(`Deleted ${deleteResult.rowCount} excess notifications for patient ${patientId}`);
    }
    
    // Verify cleanup
    const finalCount = await query(`
      SELECT patient_id, COUNT(*) as notification_count
      FROM notifications
      GROUP BY patient_id
      HAVING COUNT(*) > 20
    `);
    
    if (finalCount.rows.length === 0) {
      console.log('✅ Cleanup completed successfully! No patients have more than 20 notifications.');
    } else {
      console.log(`⚠️  Warning: ${finalCount.rows.length} patients still have more than 20 notifications`);
    }
    
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  } finally {
    process.exit(0);
  }
}

cleanupNotifications(); 