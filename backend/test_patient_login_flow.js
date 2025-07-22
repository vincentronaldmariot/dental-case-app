const http = require('http');

async function testPatientLoginFlow() {
  try {
    console.log('🔍 Testing patient login flow...');
    
    // Test 1: Patient login
    console.log('\n📋 Test 1: Patient login');
    const loginData = JSON.stringify({
      email: 'vincent@gmail.com',
      password: 'password123'
    });
    
    const loginResponse = await makeRequest('POST', '/api/auth/patient/login', {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(loginData)
    }, loginData);
    
    console.log('Login Status:', loginResponse.statusCode);
    console.log('Login Data:', JSON.stringify(loginResponse.data, null, 2));
    
    if (loginResponse.statusCode === 200) {
      const patientId = loginResponse.data.patient.id;
      const token = loginResponse.data.token;
      
      console.log('\n✅ Login successful!');
      console.log('Patient ID:', patientId);
      console.log('Token:', token.substring(0, 50) + '...');
      
      // Test 2: Test notifications with the logged-in patient
      console.log('\n📋 Test 2: Test notifications with logged-in patient');
      const notificationsResponse = await makeRequest('GET', `/api/patients/${patientId}/notifications`, {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      });
      
      console.log('Notifications Status:', notificationsResponse.statusCode);
      console.log('Notifications Count:', notificationsResponse.data.notifications?.length || 0);
      
      // Test 3: Test unread count
      console.log('\n📋 Test 3: Test unread count');
      const unreadCountResponse = await makeRequest('GET', `/api/patients/${patientId}/notifications/unread-count`, {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      });
      
      console.log('Unread Count Status:', unreadCountResponse.statusCode);
      console.log('Unread Count:', unreadCountResponse.data.unreadCount);
      
    } else {
      console.log('❌ Login failed');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

function makeRequest(method, path, headers = {}, body = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: headers
    };

    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          resolve({
            statusCode: res.statusCode,
            data: jsonData
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            data: data
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (body) {
      req.write(body);
    }
    
    req.end();
  });
}

testPatientLoginFlow(); 