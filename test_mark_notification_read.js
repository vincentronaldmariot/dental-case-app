const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testMarkNotificationRead() {
  try {
    console.log('🔍 Testing mark notification as read endpoint...');
    
    // Step 1: Login as patient
    console.log('\n1️⃣ Logging in as patient...');
    const loginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'rolex@gmail.com',
      password: 'password123'
    });
    
    console.log('✅ Login successful');
    const patientToken = loginResponse.data.token;
    const patientId = loginResponse.data.patient.id;
    
    console.log(`🔑 Patient ID: ${patientId}`);
    console.log(`🔑 Token: ${patientToken ? 'Present' : 'Missing'}`);
    
    // Step 2: Get notifications first
    console.log('\n2️⃣ Fetching notifications...');
    const notificationsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/notifications`, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Notifications fetch successful');
    console.log('📊 Response status:', notificationsResponse.status);
    
    const notifications = notificationsResponse.data.notifications || [];
    console.log(`📊 Found ${notifications.length} notifications`);
    
    // Find an unread notification
    const unreadNotification = notifications.find(n => !n.isRead);
    
    if (!unreadNotification) {
      console.log('❌ No unread notifications found to test with');
      return;
    }
    
    console.log(`📋 Found unread notification: ${unreadNotification.id} - ${unreadNotification.title}`);
    
    // Step 3: Mark notification as read
    console.log('\n3️⃣ Marking notification as read...');
    const markReadResponse = await axios.put(
      `${ONLINE_SERVER_URL}/api/patients/${patientId}/notifications/${unreadNotification.id}/read`,
      {},
      {
        headers: {
          'Authorization': `Bearer ${patientToken}`,
          'Content-Type': 'application/json'
        }
      }
    );
    
    console.log('✅ Mark as read successful');
    console.log('📊 Response status:', markReadResponse.status);
    console.log('📊 Response data:', JSON.stringify(markReadResponse.data, null, 2));
    
    // Step 4: Verify the notification is now read
    console.log('\n4️⃣ Verifying notification is now read...');
    const verifyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/notifications`, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    const updatedNotifications = verifyResponse.data.notifications || [];
    const updatedNotification = updatedNotifications.find(n => n.id === unreadNotification.id);
    
    if (updatedNotification) {
      console.log(`📊 Notification read status: ${updatedNotification.isRead}`);
      if (updatedNotification.isRead) {
        console.log('✅ Notification successfully marked as read!');
      } else {
        console.log('❌ Notification is still unread');
      }
    } else {
      console.log('❌ Could not find the notification after update');
    }
    
    // Step 5: Check unread count
    console.log('\n5️⃣ Checking unread count...');
    const unreadCountResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/notifications/unread-count`, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Unread count fetch successful');
    console.log('📊 Response status:', unreadCountResponse.status);
    console.log('📊 Response data:', JSON.stringify(unreadCountResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

testMarkNotificationRead(); 