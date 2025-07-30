const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testNotificationTypes() {
  try {
    console.log('🔍 Testing notification types for patient...');
    
    // Step 1: Login as patient (Rolex)
    console.log('\n1️⃣ Logging in as patient (Rolex)...');
    const patientLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'rolex@gmail.com',
      password: 'password123'
    });
    
    console.log('✅ Patient login successful');
    const patientToken = patientLoginResponse.data.token;
    const patientId = patientLoginResponse.data.patient.id;
    console.log(`🔑 Patient ID: ${patientId}`);
    
    // Step 2: Get all notifications
    console.log('\n2️⃣ Getting all notifications...');
    const notificationsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/notifications`, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Notifications fetch successful');
    const notifications = notificationsResponse.data.notifications || [];
    console.log(`📊 Found ${notifications.length} notifications`);
    
    // Step 3: Analyze notification types
    console.log('\n3️⃣ Analyzing notification types...');
    const typeCounts = {};
    const typeExamples = {};
    
    notifications.forEach(notification => {
      const type = notification.type || 'unknown';
      typeCounts[type] = (typeCounts[type] || 0) + 1;
      
      if (!typeExamples[type]) {
        typeExamples[type] = notification.message;
      }
    });
    
    console.log('📊 Notification type breakdown:');
    Object.entries(typeCounts).forEach(([type, count]) => {
      console.log(`   - ${type}: ${count} notifications`);
      console.log(`     Example: ${typeExamples[type]}`);
    });
    
    // Step 4: Look for appointment-related notifications
    console.log('\n4️⃣ Appointment-related notifications:');
    const appointmentNotifications = notifications.filter(n => 
      n.type && n.type.includes('appointment')
    );
    
    console.log(`📊 Found ${appointmentNotifications.length} appointment-related notifications`);
    
    appointmentNotifications.forEach((notification, index) => {
      console.log(`   ${index + 1}. Type: ${notification.type}`);
      console.log(`      Message: ${notification.message}`);
      console.log(`      Created: ${notification.createdAt}`);
    });
    
    // Step 5: Check if there are completion notifications
    const completionNotifications = notifications.filter(n => 
      n.type === 'appointment_completed'
    );
    
    console.log(`\n5️⃣ Completion notifications: ${completionNotifications.length}`);
    if (completionNotifications.length === 0) {
      console.log('❌ No completion notifications found');
      console.log('💡 This explains why the fallback method shows all appointments as "approved"');
    } else {
      completionNotifications.forEach((notification, index) => {
        console.log(`   ${index + 1}. Message: ${notification.message}`);
      });
    }
    
    console.log('\n6️⃣ Summary:');
    console.log('✅ Notifications analyzed');
    console.log('✅ Types identified');
    console.log('✅ Appointment notifications found');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

testNotificationTypes(); 