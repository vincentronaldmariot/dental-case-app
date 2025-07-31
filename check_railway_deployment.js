const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function checkRailwayDeployment() {
  console.log('🔍 Checking Railway Deployment Status\n');

  try {
    // Test basic connectivity
    console.log('1️⃣ Testing basic connectivity...');
    const healthResponse = await axios.get(`${ONLINE_SERVER_URL}/api/health`, {
      timeout: 10000
    });
    console.log('✅ Backend is responding');
    console.log('   Status:', healthResponse.status);
    console.log('   Response:', healthResponse.data);

    // Test admin login
    console.log('\n2️⃣ Testing admin login...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');

    // Test emergency endpoint
    console.log('\n3️⃣ Testing emergency endpoint...');
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
      console.log('❌ Emergency endpoint still failing:');
      console.log('   Status:', error.response?.status);
      console.log('   Error:', error.response?.data?.error || error.message);
      
      if (error.response?.status === 500) {
        console.log('\n🔧 The backend deployment might still be in progress.');
        console.log('Please wait a few more minutes and try again.');
      }
    }

    // Test other endpoints
    console.log('\n4️⃣ Testing other endpoints...');
    try {
      const patientsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });
      console.log('✅ Patients endpoint working');
    } catch (error) {
      console.log('❌ Patients endpoint failed:', error.response?.status);
    }

  } catch (error) {
    console.log('❌ Backend connectivity failed:');
    console.log('   Error:', error.message);
    
    if (error.code === 'ECONNREFUSED') {
      console.log('\n🔧 Railway deployment might be in progress.');
      console.log('Please wait a few minutes and try again.');
    }
  }

  console.log('\n📋 DEPLOYMENT STATUS:');
  console.log('If you see 500 errors, the deployment might still be in progress.');
  console.log('If you see connection errors, Railway might be restarting.');
  console.log('Please wait 2-3 minutes and test again.');
}

checkRailwayDeployment().catch(console.error); 