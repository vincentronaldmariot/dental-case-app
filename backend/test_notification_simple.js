const http = require('http');

async function testNotificationSimple() {
  try {
    console.log('🔍 Simple notification test...');
    
    const patientId = '45f784a4-ecd4-49d1-a8d0-909b25d2b03e';
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjQ1Zjc4NGE0LWVjZDQtNDlkMS1hOGQwLTkwOWIyNWQyYjAzZSIsImVtYWlsIjoidmluY2VudEBnbWFpbC5jb20iLCJ0eXBlIjoicGF0aWVudCIsImlhdCI6MTc1MzA0Mzc2MSwiZXhwIjoxNzUzNjQ4NTYxfQ.gZ0dbtkj13RHB7d-2KsTPP0BTAbMTamtIuorv-VxWsI';
    
    // Test notifications endpoint
    console.log('\n📋 Testing notifications endpoint...');
    const notificationsResponse = await makeRequest('GET', `/api/patients/${patientId}/notifications`, {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    });
    
    console.log('Status:', notificationsResponse.statusCode);
    console.log('Data:', JSON.stringify(notificationsResponse.data, null, 2));
    
    // Test unread count endpoint
    console.log('\n📋 Testing unread count endpoint...');
    const unreadCountResponse = await makeRequest('GET', `/api/patients/${patientId}/notifications/unread-count`, {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    });
    
    console.log('Status:', unreadCountResponse.statusCode);
    console.log('Data:', JSON.stringify(unreadCountResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.message);
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

    req.end();
  });
}

testNotificationSimple(); 