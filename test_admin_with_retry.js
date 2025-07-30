const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAdminWithRetry() {
  console.log('🔍 Testing Admin Endpoints with Retry...\n');

  try {
    // Test 1: Admin login
    console.log('📡 Test 1: Admin login...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    if (loginResponse.status !== 200) {
      console.log('❌ Admin login failed:', loginResponse.status);
      return;
    }

    const token = loginResponse.data.token;
    console.log('✅ Admin login successful');

    const headers = {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };

    // Test 2: Try dashboard with retry and detailed error
    console.log('\n📊 Test 2: Testing dashboard with retry...');
    
    for (let i = 1; i <= 3; i++) {
      try {
        console.log(`Attempt ${i}/3...`);
        const dashboardResponse = await axios.get(`${BASE_URL}/api/admin/dashboard`, { 
          headers,
          timeout: 10000 // 10 second timeout
        });
        console.log('✅ Dashboard successful:', dashboardResponse.status);
        console.log('📈 Stats:', JSON.stringify(dashboardResponse.data.stats, null, 2));
        break;
      } catch (error) {
        console.log(`❌ Attempt ${i} failed:`, error.response?.status);
        if (error.response?.data) {
          console.log('📋 Error details:', JSON.stringify(error.response.data, null, 2));
        }
        if (error.code === 'ECONNABORTED') {
          console.log('⏰ Request timed out');
        }
        if (i < 3) {
          console.log('⏳ Waiting 2 seconds before retry...');
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }
    }

    // Test 3: Try a simple query to see if it's a general issue
    console.log('\n🔧 Test 3: Testing simple admin query...');
    try {
      const simpleResponse = await axios.get(`${BASE_URL}/api/admin/patients?limit=1`, { headers });
      console.log('✅ Simple patients query:', simpleResponse.status);
      console.log('📊 Response:', simpleResponse.data.patients?.length || 0, 'patients');
    } catch (error) {
      console.log('❌ Simple patients query failed:', error.response?.status);
      console.log('📋 Error details:', error.response?.data);
    }

    console.log('\n📋 Summary:');
    console.log('- If dashboard works, the fix was successful');
    console.log('- If it still fails, check Railway logs for specific errors');
    console.log('- The startup logs show the database is working');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testAdminWithRetry(); 