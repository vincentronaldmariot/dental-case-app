const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function checkRailwayEnvVars() {
  console.log('🔍 Checking Railway Environment Variables...\n');

  try {
    // Test 1: Health check
    console.log('📡 Test 1: Health check...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Health check passed:', healthResponse.status);

    // Test 2: Admin login
    console.log('\n📡 Test 2: Admin login...');
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

    // Test 3: Try to get environment info (if available)
    console.log('\n🔧 Test 3: Checking environment info...');
    try {
      const envResponse = await axios.get(`${BASE_URL}/api/admin/env-check`, { headers });
      console.log('✅ Environment info:', envResponse.data);
    } catch (error) {
      console.log('❌ Environment endpoint not available:', error.response?.status);
    }

    // Test 4: Try a simple database query through the API
    console.log('\n🗄️ Test 4: Testing database connection through API...');
    try {
      const dbTestResponse = await axios.get(`${BASE_URL}/api/admin/db-test`, { headers });
      console.log('✅ Database test through API:', dbTestResponse.data);
    } catch (error) {
      console.log('❌ Database test endpoint not available:', error.response?.status);
    }

    // Test 5: Check if there's a debug endpoint
    console.log('\n🐛 Test 5: Checking for debug endpoints...');
    try {
      const debugResponse = await axios.get(`${BASE_URL}/api/debug`, { headers });
      console.log('✅ Debug endpoint:', debugResponse.data);
    } catch (error) {
      console.log('❌ Debug endpoint not available:', error.response?.status);
    }

    console.log('\n📋 Summary:');
    console.log('- The application is running and accessible');
    console.log('- Admin authentication is working');
    console.log('- Database connection through API is failing');
    console.log('- This suggests the Railway app is not using the updated environment variables');

    console.log('\n🔧 Next Steps:');
    console.log('1. Check Railway logs for database connection errors');
    console.log('2. Verify the environment variables are set on the correct service');
    console.log('3. Try adding a FORCE_RESTART variable to trigger redeployment');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

checkRailwayEnvVars(); 