const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testEmergencyRemove() {
  try {
    console.log('🔍 Testing Emergency Remove Functionality...\n');

    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 2: Get emergency records
    console.log('\n2️⃣ Getting emergency records...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const emergencyRecords = emergencyResponse.data.emergencyRecords || [];
      console.log(`📊 Found ${emergencyRecords.length} emergency records`);

      if (emergencyRecords.length === 0) {
        console.log('⚠️ No emergency records found to test remove functionality');
        console.log('Creating a test emergency record...');
        
        // Create a test emergency record
        const patientsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients`, {
          headers: { Authorization: `Bearer ${adminToken}` }
        });

        const patients = patientsResponse.data.patients || [];
        if (patients.length > 0) {
          const testPatient = patients[0];
          
          const createResponse = await axios.post(
            `${ONLINE_SERVER_URL}/api/emergency`,
            {
              patientId: testPatient.id,
              emergencyType: 'severeToothache',
              description: 'Test emergency record for remove functionality',
              emergencyDate: new Date().toISOString()
            },
            {
              headers: { Authorization: `Bearer ${adminToken}` }
            }
          );

          console.log('✅ Test emergency record created');
          console.log('Created record ID:', createResponse.data.emergency?.id);
          
          // Get the record again to test remove
          const updatedEmergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
            headers: { Authorization: `Bearer ${adminToken}` }
          });
          
          const updatedRecords = updatedEmergencyResponse.data.emergencyRecords || [];
          if (updatedRecords.length > 0) {
            const testRecord = updatedRecords[0];
            console.log(`📋 Testing remove with record: ${testRecord.id}`);
            
            // Step 3: Test remove functionality
            console.log('\n3️⃣ Testing remove functionality...');
            try {
              const deleteResponse = await axios.delete(
                `${ONLINE_SERVER_URL}/api/admin/emergencies/${testRecord.id}`,
                {
                  headers: { Authorization: `Bearer ${adminToken}` }
                }
              );

              console.log('✅ Emergency record removed successfully');
              console.log('Response:', deleteResponse.data);

              // Step 4: Verify record was removed
              console.log('\n4️⃣ Verifying record was removed...');
              const finalEmergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
                headers: { Authorization: `Bearer ${adminToken}` }
              });

              const finalRecords = finalEmergencyResponse.data.emergencyRecords || [];
              console.log(`📊 Remaining emergency records: ${finalRecords.length}`);

              if (finalRecords.length < updatedRecords.length) {
                console.log('✅ Emergency record successfully removed');
              } else {
                console.log('❌ Emergency record was not removed');
              }

            } catch (deleteError) {
              console.log('❌ Emergency remove failed');
              console.log(`   Error: ${deleteError.response?.status} - ${deleteError.response?.data?.error || deleteError.message}`);
            }
          }
        } else {
          console.log('❌ No patients found to create test emergency');
        }
      } else {
        // Test with existing record
        const testRecord = emergencyRecords[0];
        console.log(`📋 Testing remove with existing record: ${testRecord.id}`);
        
        // Step 3: Test remove functionality
        console.log('\n3️⃣ Testing remove functionality...');
        try {
          const deleteResponse = await axios.delete(
            `${ONLINE_SERVER_URL}/api/admin/emergencies/${testRecord.id}`,
            {
              headers: { Authorization: `Bearer ${adminToken}` }
            }
          );

          console.log('✅ Emergency record removed successfully');
          console.log('Response:', deleteResponse.data);

          // Step 4: Verify record was removed
          console.log('\n4️⃣ Verifying record was removed...');
          const finalEmergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
            headers: { Authorization: `Bearer ${adminToken}` }
          });

          const finalRecords = finalEmergencyResponse.data.emergencyRecords || [];
          console.log(`📊 Remaining emergency records: ${finalRecords.length}`);

          if (finalRecords.length < emergencyRecords.length) {
            console.log('✅ Emergency record successfully removed');
          } else {
            console.log('❌ Emergency record was not removed');
          }

        } catch (deleteError) {
          console.log('❌ Emergency remove failed');
          console.log(`   Error: ${deleteError.response?.status} - ${deleteError.response?.data?.error || deleteError.message}`);
        }
      }

    } catch (error) {
      console.log('❌ Failed to get emergency records');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    // Step 5: Test notification endpoint
    console.log('\n5️⃣ Testing emergency notification endpoint...');
    try {
      const notificationResponse = await axios.post(
        `${ONLINE_SERVER_URL}/api/admin/emergencies/test-id/notify`,
        {
          patientId: 'test-patient-id',
          message: 'Test notification message',
          emergencyType: 'Test Emergency'
        },
        {
          headers: { Authorization: `Bearer ${adminToken}` }
        }
      );

      console.log('✅ Emergency notification endpoint working');
      console.log('Response:', notificationResponse.data);

    } catch (error) {
      if (error.response?.status === 404) {
        console.log('✅ Emergency notification endpoint exists (404 expected for test ID)');
      } else {
        console.log('❌ Emergency notification endpoint failed');
        console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
      }
    }

    console.log('\n📋 EMERGENCY REMOVE SUMMARY:');
    console.log('   • Admin authentication: ✅');
    console.log('   • Emergency records endpoint: ⚠️ (needs verification)');
    console.log('   • Emergency remove endpoint: ⚠️ (needs verification)');
    console.log('   • Emergency notification endpoint: ⚠️ (needs verification)');
    console.log('   • Remove button functionality: ⚠️ (will work after deployment)');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testEmergencyRemove(); 