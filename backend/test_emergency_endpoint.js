const https = require('https');
const http = require('http');

const SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

// Helper function to make HTTP/HTTPS requests
function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const isHttps = url.startsWith('https://');
    const client = isHttps ? https : http;
    
    const requestOptions = {
      method: options.method || 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      }
    };

    const req = client.request(url, requestOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          resolve({
            status: res.statusCode,
            data: jsonData
          });
        } catch (e) {
          resolve({
            status: res.statusCode,
            data: data
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (options.body) {
      req.write(JSON.stringify(options.body));
    }
    req.end();
  });
}

async function testEmergencyEndpoint() {
  console.log('🔧 Testing emergency records endpoint...\n');

  try {
    // 1. Test admin login first
    console.log('1. Testing admin login...');
    const loginResponse = await makeRequest(`${SERVER_URL}/api/auth/admin/login`, {
      method: 'POST',
      body: {
        username: 'admin',
        password: 'admin123'
      }
    });

    console.log(`   Login Status: ${loginResponse.status}`);
    if (loginResponse.status !== 200) {
      console.log(`❌ Admin login failed: ${loginResponse.status} Response:`, loginResponse.data);
      return;
    }
    console.log('✅ Admin login successful!\n');

    // 2. Test emergency records endpoint
    console.log('2. Testing emergency records...');
    const emergencyResponse = await makeRequest(`${SERVER_URL}/api/admin/emergency`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${loginResponse.data.token}`
      }
    });

    console.log(`   Emergency Status: ${emergencyResponse.status}`);
    console.log(`   Emergency Response:`, JSON.stringify(emergencyResponse.data, null, 2));

    if (emergencyResponse.status === 200) {
      console.log('✅ Emergency records endpoint is working!');
    } else {
      console.log('❌ Emergency records endpoint failed');
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testEmergencyEndpoint();