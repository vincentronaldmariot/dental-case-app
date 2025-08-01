const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testEmergencyEndpoints() {
  try {
    console.log('🔍 Testing Emergency Endpoints After Schema Update\n');

    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 2: Test emergency records endpoint
    console.log('\n2️⃣ Testing emergency records endpoint...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergencies`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      console.log('✅ Emergency records endpoint working');
      console.log(`📊 Found ${emergencyResponse.data.emergencyRecords?.length || 0} emergency records`);
      
      if (emergencyResponse.data.emergencyRecords?.length > 0) {
        const record = emergencyResponse.data.emergencyRecords[0];
        console.log('📋 Sample record structure:');
        console.log(`   - ID: ${record.id} (type: ${typeof record.id})`);
        console.log(`   - Patient ID: ${record.patientId}`);
        console.log(`   - Status: ${record.status}`);
        console.log(`   - Priority: ${record.priority}`);
        console.log(`   - Emergency Type: ${record.emergencyType}`);
        console.log(`   - Pain Level: ${record.painLevel}`);
        console.log(`   - Handled By: ${record.handledBy || 'Not assigned'}`);
      }

    } catch (error) {
      console.log('❌ Emergency records endpoint failing');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
      if (error.response?.data?.details) {
        console.log(`   Details: ${JSON.stringify(error.response.data.details, null, 2)}`);
      }
    }

    // Step 3: Test emergency status update
    console.log('\n3️⃣ Testing emergency status update...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergencies`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const emergencyRecords = emergencyResponse.data.emergencyRecords || [];
      
      if (emergencyRecords.length > 0) {
        const testRecord = emergencyRecords[0];
        console.log(`📋 Testing with record: ${testRecord.id}`);

        const updateResponse = await axios.put(
          `${ONLINE_SERVER_URL}/api/admin/emergencies/${testRecord.id}/status`,
          {
            status: 'in_progress',
            handledBy: 'Dr. Admin Test',
            resolution: 'Test status update'
          },
          {
            headers: { Authorization: `Bearer ${adminToken}` }
          }
        );

        console.log('✅ Emergency status update working');
        console.log('Response:', updateResponse.data);

      } else {
        console.log('⚠️ No emergency records to test with');
      }

    } catch (error) {
      console.log('❌ Emergency status update failing');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    console.log('\n🎉 Emergency Endpoints Test Complete!');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testEmergencyEndpoints(); 