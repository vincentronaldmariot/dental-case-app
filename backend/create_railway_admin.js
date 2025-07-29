const https = require('https');

function makeRequest(url, method = 'POST', data = null, customHeaders = {}) {
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

async function createRailwayAdmin() {
  const baseUrl = 'https://afp-dental-app-production.up.railway.app';
  
  console.log('🔧 Creating admin user on Railway server...\n');
  
  try {
    // First, try to login with admin credentials to see if they exist
    console.log('1. Testing admin login...');
    const loginResponse = await makeRequest(`${baseUrl}/api/auth/admin/login`, 'POST', {
      username: 'admin',
      password: 'admin123'
    });
    
    console.log(`   Login Status: ${loginResponse.statusCode}`);
    console.log(`   Login Response: ${loginResponse.body}`);
    
    if (loginResponse.statusCode === 200) {
      console.log('✅ Admin user already exists and can login!');
      
      // Test admin dashboard access
      const token = JSON.parse(loginResponse.body).token;
      console.log('\n2. Testing admin dashboard access...');
      
      const dashboardResponse = await makeRequest(`${baseUrl}/api/admin/dashboard`, 'GET', null, {
        'Authorization': `Bearer ${token}`
      });
      
      console.log(`   Dashboard Status: ${dashboardResponse.statusCode}`);
      console.log(`   Dashboard Response: ${dashboardResponse.body}`);
      
    } else {
      console.log('❌ Admin login failed - user may not exist');
    }
    
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
}

createRailwayAdmin();