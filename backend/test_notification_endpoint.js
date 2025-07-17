const http = require('http');

async function testNotificationEndpoints() {
  try {
    // First, get a patient token
    console.log('Getting patient token...');
    const loginData = JSON.stringify({
      email: 'test@example.com',
      password: 'password123'
    });

    const loginOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/patient/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(loginData)
      }
    };

    const tokenResponse = await new Promise((resolve, reject) => {
      const req = http.request(loginOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            resolve({ status: res.statusCode, data: response });
          } catch (e) {
            reject(e);
          }
        });
      });
      req.on('error', reject);
      req.write(loginData);
      req.end();
    });

    if (tokenResponse.status !== 200) {
      console.log('❌ Failed to get patient token:', tokenResponse.data);
      return;
    }

    const token = tokenResponse.data.token;
    const patientId = tokenResponse.data.patient.id;
    console.log('✅ Patient token received');
    console.log(`Patient ID: ${patientId}`);

    // Test notifications endpoint
    console.log('\nTesting notifications endpoint...');
    const notificationsOptions = {
      hostname: 'localhost',
      port: 3000,
      path: `/api/patients/${patientId}/notifications`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };

    const notificationsResponse = await new Promise((resolve, reject) => {
      const req = http.request(notificationsOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            resolve({ status: res.statusCode, data: response });
          } catch (e) {
            reject(e);
          }
        });
      });
      req.on('error', reject);
      req.end();
    });

    console.log('Notifications response:');
    console.log('Status:', notificationsResponse.status);
    console.log('Data:', JSON.stringify(notificationsResponse.data, null, 2));

    // Test unread count endpoint
    console.log('\nTesting unread count endpoint...');
    const unreadOptions = {
      hostname: 'localhost',
      port: 3000,
      path: `/api/patients/${patientId}/notifications/unread-count`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };

    const unreadResponse = await new Promise((resolve, reject) => {
      const req = http.request(unreadOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            resolve({ status: res.statusCode, data: response });
          } catch (e) {
            reject(e);
          }
        });
      });
      req.on('error', reject);
      req.end();
    });

    console.log('Unread count response:');
    console.log('Status:', unreadResponse.status);
    console.log('Data:', JSON.stringify(unreadResponse.data, null, 2));

  } catch (error) {
    console.error('❌ Error:', error);
  }
}

testNotificationEndpoints(); 