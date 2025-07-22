const http = require('http');

async function testNotificationEndpoint() {
  try {
    console.log('🔍 Testing notification endpoint...');
    
    const patientId = '45f784a4-ecd4-49d1-a8d0-909b25d2b03e';
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjQ1Zjc4NGE0LWVjZDQtNDlkMS1hOGQwLTkwOWIyNWQyYjAzZSIsImVtYWlsIjoidmluY2VudEBnbWFpbC5jb20iLCJ0eXBlIjoicGF0aWVudCIsImlhdCI6MTc1MzA0Mzc2MSwiZXhwIjoxNzUzNjQ4NTYxfQ.gZ0dbtkj13RHB7d-2KsTPP0BTAbMTamtIuorv-VxWsI';
    
    // Test 1: Check if server is running
    console.log('\n📋 Test 1: Check if server is running');
    const healthCheck = await makeRequest('GET', '/health');
    console.log('Health check response:', healthCheck);
    
    // Test 2: Test notifications endpoint
    console.log('\n📋 Test 2: Test notifications endpoint');
    const notificationsResponse = await makeRequest('GET', `/api/patients/${patientId}/notifications`, {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    });
    console.log('Notifications response:', notificationsResponse);
    
    // Test 3: Test unread count endpoint
    console.log('\n📋 Test 3: Test unread count endpoint');
    const unreadCountResponse = await makeRequest('GET', `/api/patients/${patientId}/notifications/unread-count`, {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    });
    console.log('Unread count response:', unreadCountResponse);
    
  } catch (error) {
    console.error('❌ Error testing notification endpoint:', error);
  }
}

function makeRequest(method, path, headers = {}) {
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
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: jsonData
          });
        } catch (e) {
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            data: data
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.end();
  });
}

testNotificationEndpoint(); 