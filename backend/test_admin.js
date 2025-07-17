const http = require('http');

async function testAdminEndpoints() {
  try {
    // First, get admin token
    console.log('Getting admin token...');
    const loginData = JSON.stringify({
      username: 'admin',
      password: 'admin123'
    });

    const loginOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/admin/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(loginData)
      }
    };

    const token = await new Promise((resolve, reject) => {
      const req = http.request(loginOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            resolve(response.token);
          } catch (e) {
            reject(e);
          }
        });
      });
      req.on('error', reject);
      req.write(loginData);
      req.end();
    });

    console.log('Token received:', token);

    // Now test pending appointments endpoint
    console.log('\nTesting pending appointments endpoint...');
    const pendingOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/admin/appointments/pending',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };

    const pendingResponse = await new Promise((resolve, reject) => {
      const req = http.request(pendingOptions, (res) => {
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

    console.log('Pending appointments response:');
    console.log('Status:', pendingResponse.status);
    console.log('Data:', JSON.stringify(pendingResponse.data, null, 2));

  } catch (error) {
    console.error('Error:', error);
  }
}

testAdminEndpoints(); 