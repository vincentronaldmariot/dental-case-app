const https = require('https');

function makeRequest(url, method = 'GET', data = null, customHeaders = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || 443,
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...customHeaders
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: responseData
        });
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function testPendingAppointments() {
  const baseUrl = 'https://afp-dental-app-production.up.railway.app';
  
  console.log('🔧 Testing pending appointments endpoint...\n');
  
  try {
    // 1. Admin login
    console.log('1. Testing admin login...');
    const loginResponse = await makeRequest(`${baseUrl}/api/auth/admin/login`, 'POST', {
      username: 'admin',
      password: 'admin123'
    });
    
    console.log(`   Login Status: ${loginResponse.statusCode}`);
    
    if (loginResponse.statusCode === 200) {
      const token = JSON.parse(loginResponse.body).token;
      console.log('✅ Admin login successful!');
      
      // 2. Test pending appointments
      console.log('\n2. Testing pending appointments...');
      const pendingResponse = await makeRequest(`${baseUrl}/api/admin/pending-appointments`, 'GET', null, {
        'Authorization': `Bearer ${token}`
      });
      console.log(`   Pending Appointments Status: ${pendingResponse.statusCode}`);
      console.log(`   Pending Appointments Response: ${pendingResponse.body}`);
      
      if (pendingResponse.statusCode === 200) {
        console.log('✅ Pending appointments endpoint is working!');
      } else {
        console.log('❌ Pending appointments endpoint failed');
      }
      
    } else {
      console.log('❌ Admin login failed');
    }
    
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
}

testPendingAppointments();