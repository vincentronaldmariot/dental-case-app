const http = require('http');

async function testNotificationEndpoint() {
  console.log('🔍 Testing notification endpoint...\n');

  // First, get a real patient token
  console.log('📋 Step 1: Getting patient token...');
  const loginResponse = await makeRequest('POST', '/api/auth/login', {
    email: 'john.doe@test.com',
    password: 'password123'
  });

  if (loginResponse.statusCode !== 200) {
    console.log('❌ Failed to get patient token');
    console.log(`Status: ${loginResponse.statusCode}`);
    console.log(`Response: ${JSON.stringify(loginResponse.data)}`);
    return;
  }

  const loginData = loginResponse.data; // Already parsed by makeRequest
  const token = loginData.token;
  const patientId = loginData.patient.id;

  console.log(`✅ Got token for patient: ${loginData.patient.firstName} ${loginData.patient.lastName}`);
  console.log(`📊 Patient ID: ${patientId}`);

  // Test notifications endpoint with real token
  console.log('\n📋 Step 2: Testing notifications endpoint...');
  const notificationsResponse = await makeRequest(
    'GET', 
    `/api/patients/${patientId}/notifications`,
    null,
    { 'Authorization': `Bearer ${token}` }
  );

  console.log('Notifications response:', {
    statusCode: notificationsResponse.statusCode,
    data: notificationsResponse.data // Already parsed
  });

  // Test unread count endpoint
  console.log('\n📋 Step 3: Testing unread count endpoint...');
  const unreadResponse = await makeRequest(
    'GET', 
    `/api/patients/${patientId}/notifications/unread-count`,
    null,
    { 'Authorization': `Bearer ${token}` }
  );

  console.log('Unread count response:', {
    statusCode: unreadResponse.statusCode,
    data: unreadResponse.data // Already parsed
  });
}

function makeRequest(method, path, body = null, headers = {}) {
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

    let dataToSend = '';
    if (body) {
      dataToSend = JSON.stringify(body);
    }

    const req = http.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(responseData);
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: jsonData
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: responseData
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (dataToSend) {
      req.write(dataToSend);
    }
    req.end();
  });
}

testNotificationEndpoint(); 