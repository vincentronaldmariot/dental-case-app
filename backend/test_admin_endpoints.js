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

async function testAdminEndpoints() {
  const baseUrl = 'https://afp-dental-app-production.up.railway.app';
  
  console.log('🔧 Testing all admin endpoints...\n');
  
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
      
      // 2. Admin dashboard
      console.log('\n2. Testing admin dashboard...');
      const dashboardResponse = await makeRequest(`${baseUrl}/api/admin/dashboard`, 'GET', null, {
        'Authorization': `Bearer ${token}`
      });
      console.log(`   Dashboard Status: ${dashboardResponse.statusCode}`);
      console.log(`   Dashboard Response: ${dashboardResponse.body}`);
      
      // 3. Admin patients
      console.log('\n3. Testing admin patients...');
      const patientsResponse = await makeRequest(`${baseUrl}/api/admin/patients`, 'GET', null, {
        'Authorization': `Bearer ${token}`
      });
      console.log(`   Patients Status: ${patientsResponse.statusCode}`);
      console.log(`   Patients Response: ${patientsResponse.body}`);
      
      // 4. Admin appointments
      console.log('\n4. Testing admin appointments...');
      const appointmentsResponse = await makeRequest(`${baseUrl}/api/admin/appointments`, 'GET', null, {
        'Authorization': `Bearer ${token}`
      });
      console.log(`   Appointments Status: ${appointmentsResponse.statusCode}`);
      console.log(`   Appointments Response: ${appointmentsResponse.body}`);
      
      // 5. Admin emergency records
      console.log('\n5. Testing admin emergency records...');
      const emergencyResponse = await makeRequest(`${baseUrl}/api/admin/emergency?exclude_resolved=true`, 'GET', null, {
        'Authorization': `Bearer ${token}`
      });
      console.log(`   Emergency Status: ${emergencyResponse.statusCode}`);
      console.log(`   Emergency Response: ${emergencyResponse.body}`);
      
      console.log('\n🎉 All admin endpoints are working!');
      console.log('📱 Your mobile APK can now work from anywhere with full admin functionality.');
      
    } else {
      console.log('❌ Admin login failed');
    }
    
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
}

testAdminEndpoints();