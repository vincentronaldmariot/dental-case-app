const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function simpleEmergencyTest() {
  try {
    console.log('🔍 Simple Emergency API Test...\n');

    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 2: Test emergency admin endpoint
    console.log('\n2️⃣ Testing emergency admin endpoint...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/emergency-admin`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      console.log('✅ Emergency admin endpoint working!');
      console.log(`📊 Response type: ${typeof emergencyResponse.data}`);
      console.log(`📊 Data length: ${Array.isArray(emergencyResponse.data) ? emergencyResponse.data.length : 'N/A'}`);
      
      if (Array.isArray(emergencyResponse.data) && emergencyResponse.data.length > 0) {
        console.log('\n📋 Sample emergency record:');
        console.log(JSON.stringify(emergencyResponse.data[0], null, 2));
      }

    } catch (error) {
      console.log('❌ Emergency admin endpoint failed');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
      if (error.response?.data?.details) {
        console.log(`   Details: ${error.response.data.details}`);
      }
    }

    // Step 3: Test emergency status update endpoint
    console.log('\n3️⃣ Testing emergency status update endpoint...');
    try {
      // First get emergency records to find one to update
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/emergency-admin`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const emergencyRecords = emergencyResponse.data || [];
      
      if (emergencyRecords.length > 0) {
        const testRecord = emergencyRecords[0];
        console.log(`📋 Testing with emergency record: ${testRecord.id}`);

        const updateResponse = await axios.put(
          `${ONLINE_SERVER_URL}/api/emergency-admin/${testRecord.id}/status`,
          {
            status: 'inProgress',
            notes: 'Test status update from admin dashboard'
          },
          {
            headers: { Authorization: `Bearer ${adminToken}` }
          }
        );

        console.log('✅ Emergency status update working!');
        console.log(`📊 Response: ${JSON.stringify(updateResponse.data, null, 2)}`);
      } else {
        console.log('⚠️ No emergency records found to test status update');
      }

    } catch (error) {
      console.log('❌ Emergency status update failed');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
      if (error.response?.data?.details) {
        console.log(`   Details: ${error.response.data.details}`);
      }
    }

  } catch (error) {
    console.log('❌ Test failed:', error.message);
  }
}

simpleEmergencyTest(); 