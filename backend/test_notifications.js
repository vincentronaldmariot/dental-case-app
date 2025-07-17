const { query } = require('./config/database');

async function testNotifications() {
  try {
    console.log('🔍 Checking notifications in database...');
    
    // Get all notifications
    const result = await query(`
      SELECT 
        n.id,
        n.title,
        n.message,
        n.type,
        n.is_read,
        n.created_at,
        p.first_name,
        p.last_name,
        p.email
      FROM notifications n
      JOIN patients p ON n.patient_id = p.id
      ORDER BY n.created_at DESC
      LIMIT 10
    `);
    
    console.log(`📊 Found ${result.rows.length} notifications in database:`);
    console.log('');
    
    if (result.rows.length === 0) {
      console.log('❌ No notifications found in database');
      return;
    }
    
    result.rows.forEach((notification, index) => {
      console.log(`📋 Notification ${index + 1}:`);
      console.log(`   ID: ${notification.id}`);
      console.log(`   Title: ${notification.title}`);
      console.log(`   Type: ${notification.type}`);
      console.log(`   Patient: ${notification.first_name} ${notification.last_name} (${notification.email})`);
      console.log(`   Read: ${notification.is_read ? 'Yes' : 'No'}`);
      console.log(`   Created: ${notification.created_at}`);
      console.log(`   Message: ${notification.message.substring(0, 100)}${notification.message.length > 100 ? '...' : ''}`);
      console.log('');
    });
    
    // Get unread count for the test user
    const testUserResult = await query(`
      SELECT COUNT(*) as count
      FROM notifications n
      JOIN patients p ON n.patient_id = p.id
      WHERE p.email = 'test@example.com' AND n.is_read = false
    `);
    
    console.log(`📈 Test User (test@example.com) has ${testUserResult.rows[0].count} unread notifications`);
    
  } catch (error) {
    console.error('❌ Error checking notifications:', error);
  }
}

testNotifications(); 