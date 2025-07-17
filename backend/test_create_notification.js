const { query } = require('./config/database');

async function testCreateNotification() {
  try {
    console.log('Testing notification creation...');
    
    // First, get a patient ID
    const patientResult = await query('SELECT id FROM patients LIMIT 1');
    if (patientResult.rows.length === 0) {
      console.log('❌ No patients found in database');
      return;
    }
    
    const patientId = patientResult.rows[0].id;
    console.log(`Using patient ID: ${patientId}`);
    
    // Create a test notification
    const insertResult = await query(`
      INSERT INTO notifications (patient_id, title, message, type, created_at)
      VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
      RETURNING id, title, message, type, created_at
    `, [
      patientId,
      'Test Notification',
      'This is a test notification message',
      'test'
    ]);
    
    console.log('✅ Notification created successfully:');
    console.log(JSON.stringify(insertResult.rows[0], null, 2));
    
    // Verify it was created
    const countResult = await query('SELECT COUNT(*) as count FROM notifications');
    console.log(`Total notifications now: ${countResult.rows[0].count}`);
    
  } catch (error) {
    console.error('❌ Error creating notification:', error);
  }
}

testCreateNotification(); 