const { query } = require('./config/database');

async function testNotificationsTable() {
  try {
    console.log('🔍 Testing notifications table...');
    
    // Test 1: Check if notifications table exists
    console.log('\n📋 Test 1: Check if notifications table exists');
    const tableExists = await query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'notifications'
      );
    `);
    
    console.log('Notifications table exists:', tableExists.rows[0].exists);
    
    if (!tableExists.rows[0].exists) {
      console.log('❌ Notifications table does not exist!');
      return;
    }
    
    // Test 2: Check table structure
    console.log('\n📋 Test 2: Check table structure');
    const tableStructure = await query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'notifications'
      ORDER BY ordinal_position;
    `);
    
    console.log('Table structure:');
    tableStructure.rows.forEach(row => {
      console.log(`- ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });
    
    // Test 3: Check if there are any notifications
    console.log('\n📋 Test 3: Check existing notifications');
    const notifications = await query('SELECT COUNT(*) as count FROM notifications');
    console.log('Total notifications:', notifications.rows[0].count);
    
    if (parseInt(notifications.rows[0].count) > 0) {
      const sampleNotifications = await query(`
        SELECT id, patient_id, type, title, message, is_read, created_at
        FROM notifications 
        ORDER BY created_at DESC 
        LIMIT 5
      `);
      
      console.log('Sample notifications:');
      sampleNotifications.rows.forEach((notification, index) => {
        console.log(`${index + 1}. ID: ${notification.id}`);
        console.log(`   Patient ID: ${notification.patient_id}`);
        console.log(`   Type: ${notification.type}`);
        console.log(`   Title: ${notification.title}`);
        console.log(`   Message: ${notification.message}`);
        console.log(`   Is Read: ${notification.is_read}`);
        console.log(`   Created: ${notification.created_at}`);
        console.log('');
      });
    }
    
    // Test 4: Check if we can insert a test notification
    console.log('\n📋 Test 4: Test notification insertion');
    const testPatientId = '45f784a4-ecd4-49d1-a8d0-909b25d2b03e'; // From the token you provided
    
    const insertResult = await query(`
      INSERT INTO notifications (patient_id, type, title, message)
      VALUES ($1, 'test', 'Test Notification', 'This is a test notification')
      RETURNING id, patient_id, type, title, message, is_read, created_at
    `, [testPatientId]);
    
    console.log('Test notification inserted:', insertResult.rows[0]);
    
    // Test 5: Test notification retrieval
    console.log('\n📋 Test 5: Test notification retrieval');
    const retrievedNotifications = await query(`
      SELECT id, title, message, type, is_read, created_at
      FROM notifications 
      WHERE patient_id = $1
      ORDER BY created_at DESC
      LIMIT 10
    `, [testPatientId]);
    
    console.log('Retrieved notifications for patient:', retrievedNotifications.rows.length);
    retrievedNotifications.rows.forEach((notification, index) => {
      console.log(`${index + 1}. ${notification.title}: ${notification.message}`);
    });
    
    // Clean up test data
    await query('DELETE FROM notifications WHERE type = $1', ['test']);
    console.log('\n✅ Test completed successfully!');
    
  } catch (error) {
    console.error('❌ Error testing notifications table:', error);
  }
}

testNotificationsTable(); 