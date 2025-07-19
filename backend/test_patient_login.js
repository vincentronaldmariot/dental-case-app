const http = require('http');

async function testPatientLogin() {
  console.log('🔐 Testing Patient Login...\n');

  const loginData = {
    email: 'vincent@gmail.com',
    password: 'password123'
  };

  try {
    const response = await makeRequest(
      'POST',
      '/api/auth/login',
      loginData
    );
    
    if (response.statusCode === 200) {
      const data = JSON.parse(response.body);
      console.log('✅ Patient login successful');
      console.log(`📊 Patient ID: ${data.patient.id}`);
      console.log(`🔑 Token: ${data.token.substring(0, 50)}...`);
      
      // Now test notifications with the real token
      console.log('\n📱 Testing notifications with real token...');
      await testNotifications(data.token, data.patient.id);
    } else {
      console.log(`❌ Login failed: ${response.statusCode}`);
      console.log(`Response: ${response.body}`);
      
      // Try alternative credentials
      console.log('\n🔄 Trying alternative credentials...');
      const altLoginData = {
        email: 'vincent@gmail.com',
        password: '123456'
      };
      
      const altResponse = await makeRequest(
        'POST',
        '/api/auth/login',
        altLoginData
      );
      
      if (altResponse.statusCode === 200) {
        const altData = JSON.parse(altResponse.body);
        console.log('✅ Patient login successful with alternative password');
        console.log(`📊 Patient ID: ${altData.patient.id}`);
        console.log(`🔑 Token: ${altData.token.substring(0, 50)}...`);
        
        await testNotifications(altData.token, altData.patient.id);
      } else {
        console.log(`❌ Alternative login also failed: ${altResponse.statusCode}`);
        console.log(`Response: ${altResponse.body}`);
      }
    }
  } catch (error) {
    console.log(`❌ Error during login: ${error.message}`);
  }
}

async function testNotifications(token, patientId) {
  try {
    const response = await makeRequest(
      'GET',
      `/api/patients/${patientId}/notifications`,
      null,
      { 'Authorization': `Bearer ${token}` }
    );
    
    if (response.statusCode === 200) {
      const data = JSON.parse(response.body);
      console.log('✅ Notifications loaded successfully');
      console.log(`📊 Total notifications: ${data.notifications.length}`);
      
      if (data.notifications.length > 0) {
        console.log('\n📋 Recent notifications:');
        data.notifications.slice(0, 3).forEach((notification, index) => {
          console.log(`\n${index + 1}. ${notification.title}`);
          console.log(`   Message: ${notification.message}`);
          console.log(`   Type: ${notification.type}`);
          console.log(`   Read: ${notification.isRead}`);
          console.log(`   Date: ${notification.createdAt}`);
        });
      } else {
        console.log('📭 No notifications found');
      }
      
      // Test unread count
      console.log('\n🔢 Testing unread count...');
      const unreadResponse = await makeRequest(
        'GET',
        `/api/patients/${patientId}/notifications/unread-count`,
        null,
        { 'Authorization': `Bearer ${token}` }
      );
      
      if (unreadResponse.statusCode === 200) {
        const unreadData = JSON.parse(unreadResponse.body);
        console.log(`📊 Unread notifications: ${unreadData.unreadCount}`);
      }
    } else {
      console.log(`❌ Failed to load notifications: ${response.statusCode}`);
      console.log(`Response: ${response.body}`);
    }
  } catch (error) {
    console.log(`❌ Error testing notifications: ${error.message}`);
  }
}

function makeRequest(method, path, data, headers = {}) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...headers
      }
    };

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: body
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

// Run the test
testPatientLogin().catch(console.error); 