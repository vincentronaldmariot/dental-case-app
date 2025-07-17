const { query } = require('./config/database');

async function checkNotifications() {
  try {
    console.log('Checking notifications table...');
    
    // Simple count query
    const countResult = await query('SELECT COUNT(*) as count FROM notifications');
    console.log(`Total notifications: ${countResult.rows[0].count}`);
    
    if (countResult.rows[0].count > 0) {
      // Get the latest notification
      const latestResult = await query(`
        SELECT * FROM notifications 
        ORDER BY created_at DESC 
        LIMIT 1
      `);
      
      console.log('Latest notification:');
      console.log(JSON.stringify(latestResult.rows[0], null, 2));
    }
    
  } catch (error) {
    console.error('Error:', error);
  }
}

checkNotifications(); 