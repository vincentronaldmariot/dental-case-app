const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testBackendStatus() {
  console.log('🔍 Testing Backend Status\n');

  try {
    // Test 1: Basic connectivity
    console.log('1️⃣ Testing basic connectivity...');
    try {
      const response = await axios.get(`${ONLINE_SERVER_URL}/`, {
        timeout: 10000
      });
      console.log('✅ Root endpoint responding');
      console.log('   Status:', response.status);
    } catch (error) {
      console.log('❌ Root endpoint failed:', error.response?.status || error.message);
    }

    // Test 2: Health endpoint
    console.log('\n2️⃣ Testing health endpoint...');
    try {
      const healthResponse = await axios.get(`${ONLINE_SERVER_URL}/health`, {
        timeout: 10000
      });
      console.log('✅ Health endpoint working');
      console.log('   Status:', healthResponse.status);
    } catch (error) {
      console.log('❌ Health endpoint failed:', error.response?.status || error.message);
    }

    // Test 3: API health endpoint
    console.log('\n3️⃣ Testing API health endpoint...');
    try {
      const apiHealthResponse = await axios.get(`${ONLINE_SERVER_URL}/api/health`, {
        timeout: 10000
      });
      console.log('✅ API health endpoint working');
      console.log('   Status:', apiHealthResponse.status);
    } catch (error) {
      console.log('❌ API health endpoint failed:', error.response?.status || error.message);
    }

    // Test 4: Admin login
    console.log('\n4️⃣ Testing admin login...');
    try {
      const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
        username: 'admin',
        password: 'admin123'
      }, {
        timeout: 10000
      });
      
      console.log('✅ Admin login working');
      console.log('   Status:', adminLoginResponse.status);
      
      const adminToken = adminLoginResponse.data.token;
      
      // Test 5: Emergency endpoint with token
      console.log('\n5️⃣ Testing emergency endpoint...');
      try {
        const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
          headers: {
            'Authorization': `Bearer ${adminToken}`
          },
          timeout: 10000
        });
        
        console.log('✅ Emergency endpoint working!');
        console.log('   Status:', emergencyResponse.status);
        console.log('   Records found:', emergencyResponse.data.emergencyRecords?.length || 0);
        
      } catch (error) {
        console.log('❌ Emergency endpoint failed:');
        console.log('   Status:', error.response?.status);
        console.log('   Error:', error.response?.data?.error || error.message);
        
        if (error.response?.status === 500) {
          console.log('\n🔧 The emergency endpoint is returning 500 errors.');
          console.log('This suggests the database schema fix might not be working.');
        }
      }
      
    } catch (error) {
      console.log('❌ Admin login failed:', error.response?.status || error.message);
    }

  } catch (error) {
    console.log('❌ Backend connectivity failed:');
    console.log('   Error:', error.message);
  }

  console.log('\n📋 BACKEND STATUS SUMMARY:');
  console.log('If you see 404 errors, the deployment might still be in progress.');
  console.log('If you see 500 errors on emergency endpoint, the database fix might not be working.');
  console.log('If admin login works but emergency fails, it\'s a database issue.');
}

testBackendStatus().catch(console.error); 