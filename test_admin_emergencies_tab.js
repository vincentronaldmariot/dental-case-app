const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAdminEmergenciesTab() {
  try {
    console.log('🔍 Testing Admin Emergencies Tab...\n');

    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 2: Test getting all emergency records as admin
    console.log('\n2️⃣ Testing emergency records endpoint...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const emergencyRecords = emergencyResponse.data.emergencyRecords || [];
      console.log(`📊 Found ${emergencyRecords.length} emergency records`);

      if (emergencyRecords.length > 0) {
        console.log('\n📋 Emergency Records Summary:');
        emergencyRecords.forEach((record, index) => {
          console.log(`   ${index + 1}. ${record.emergencyType} - ${record.status} (Priority: ${record.priority})`);
          console.log(`      Patient: ${record.patientName || 'Unknown'}`);
          console.log(`      Reported: ${record.reportedAt}`);
          console.log(`      Description: ${record.description?.substring(0, 50)}...`);
        });
      } else {
        console.log('⚠️ No emergency records found');
      }

    } catch (error) {
      console.log('❌ Emergency records endpoint failed');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    // Step 3: Test getting emergency records statistics
    console.log('\n3️⃣ Testing emergency statistics...');
    try {
      // Get emergency records and calculate statistics manually
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      
      const emergencyRecords = emergencyResponse.data.emergencyRecords || [];
      const stats = {
        total: emergencyRecords.length,
        active: emergencyRecords.filter(r => r.status !== 'resolved').length,
        resolved: emergencyRecords.filter(r => r.status === 'resolved').length,
        immediate: emergencyRecords.filter(r => r.priority === 'immediate').length,
        urgent: emergencyRecords.filter(r => r.priority === 'urgent').length,
        standard: emergencyRecords.filter(r => r.priority === 'standard').length
      };

      console.log('📊 Emergency Statistics:');
      console.log(`   • Total emergencies: ${stats.total || 0}`);
      console.log(`   • Active emergencies: ${stats.active || 0}`);
      console.log(`   • Resolved emergencies: ${stats.resolved || 0}`);
      console.log(`   • Immediate priority: ${stats.immediate || 0}`);
      console.log(`   • Urgent priority: ${stats.urgent || 0}`);
      console.log(`   • Standard priority: ${stats.standard || 0}`);

    } catch (error) {
      console.log('❌ Emergency statistics endpoint failed');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    // Step 4: Test updating emergency record status
    console.log('\n4️⃣ Testing emergency status update...');
    try {
      // First get emergency records to find one to update
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const emergencyRecords = emergencyResponse.data.emergencyRecords || [];
      
      if (emergencyRecords.length > 0) {
        const testRecord = emergencyRecords[0];
        console.log(`📋 Testing with emergency record: ${testRecord.id}`);

        const updateResponse = await axios.put(
          `${ONLINE_SERVER_URL}/api/admin/emergency/${testRecord.id}/status`,
          {
            status: 'inProgress',
            notes: 'Test status update from admin dashboard'
          },
          {
            headers: { Authorization: `Bearer ${adminToken}` }
          }
        );

        console.log('✅ Emergency status update successful');
        console.log('Response:', updateResponse.data);

      } else {
        console.log('⚠️ No emergency records to test status update');
      }

    } catch (error) {
      console.log('❌ Emergency status update failed');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    // Step 5: Test creating a test emergency record
    console.log('\n5️⃣ Testing emergency record creation...');
    try {
      // First get a patient to associate with the emergency
      const patientsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const patients = patientsResponse.data.patients || [];
      
      if (patients.length > 0) {
        const testPatient = patients[0];
        console.log(`📋 Creating test emergency for patient: ${testPatient.firstName} ${testPatient.lastName}`);

        const createResponse = await axios.post(
          `${ONLINE_SERVER_URL}/api/emergency-records`,
          {
            patientId: testPatient.id,
            emergencyType: 'severeToothache',
            priority: 'urgent',
            description: 'Test emergency record from admin dashboard',
            painLevel: 8,
            symptoms: ['Severe pain', 'Swelling'],
            location: 'Test location',
            dutyRelated: false,
            emergencyContact: '(02) 1234-5678'
          },
          {
            headers: { Authorization: `Bearer ${adminToken}` }
          }
        );

        console.log('✅ Emergency record creation successful');
        console.log('Created record ID:', createResponse.data.emergencyRecord?.id);

        // Note: No delete endpoint available, so we'll just log the creation
        console.log('📝 Test emergency record created (no cleanup endpoint available)');

      } else {
        console.log('⚠️ No patients found to create test emergency');
      }

    } catch (error) {
      console.log('❌ Emergency record creation failed');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    console.log('\n📋 EMERGENCIES TAB SUMMARY:');
    console.log('   • Admin authentication: ✅');
    console.log('   • Emergency records endpoint: ⚠️ (needs verification)');
    console.log('   • Emergency statistics: ⚠️ (needs verification)');
    console.log('   • Status update functionality: ⚠️ (needs verification)');
    console.log('   • Record creation: ⚠️ (needs verification)');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testAdminEmergenciesTab(); 