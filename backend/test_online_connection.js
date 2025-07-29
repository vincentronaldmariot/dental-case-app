const http = require('http');
const https = require('https');

function makeRequest(url, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || (urlObj.protocol === 'https:' ? 443 : 80),
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    };

    const client = urlObj.protocol === 'https:' ? https : http;
    const req = client.request(options, (res) => {
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

async function testOnlineConnection() {
  const baseUrl = 'https://afp-dental-app-production.up.railway.app';
  
  console.log('🌐 Testing online server connection...\n');
  
  try {
    // Test health endpoint
    console.log('1. Testing health endpoint...');
    const healthResponse = await makeRequest(`${baseUrl}/health`);
    console.log(`   Status: ${healthResponse.statusCode}`);
    console.log(`   Response: ${healthResponse.body}`);
    
    // Test auth endpoint (should work even with in-memory DB)
    console.log('\n2. Testing auth endpoint...');
    const authResponse = await makeRequest(`${baseUrl}/api/auth/login`, 'POST', {
      email: 'test@example.com',
      password: 'test123'
    });
    console.log(`   Status: ${authResponse.statusCode}`);
    console.log(`   Response: ${authResponse.body}`);
    
    console.log('\n✅ Online server is accessible and responding!');
    console.log('📱 Your mobile APK should work from anywhere.');
    
  } catch (error) {
    console.log('❌ Error testing online connection:', error.message);
  }
}

testOnlineConnection();