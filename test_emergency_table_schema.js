const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testEmergencyTableSchema() {
  try {
    console.log('🔍 Testing Emergency Records Table Schema...\n');

    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 2: Try to create a simple emergency record to test the schema
    console.log('\n2️⃣ Testing emergency record creation...');
    try {
      // First get a patient
      const patientsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const patients = patientsResponse.data.patients || [];
      
      if (patients.length > 0) {
        const testPatient = patients[0];
        console.log(`📋 Using patient: ${testPatient.firstName} ${testPatient.lastName} (${testPatient.id})`);

        // Try to create a minimal emergency record
        const createResponse = await axios.post(
          `${ONLINE_SERVER_URL}/api/emergency`,
          {
            patientId: testPatient.id,
            emergencyType: 'severeToothache',
            description: 'Test emergency record',
            emergencyDate: new Date().toISOString()
          },
          {
            headers: { Authorization: `Bearer ${adminToken}` }
          }
        );

        console.log('✅ Emergency record creation successful');
        console.log('Response:', createResponse.data);

      } else {
        console.log('⚠️ No patients found to test with');
      }

    } catch (error) {
      console.log('❌ Emergency record creation failed');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
      
      if (error.response?.data?.details) {
        console.log(`   Details: ${JSON.stringify(error.response.data.details, null, 2)}`);
      }
    }

    // Step 3: Check what columns the admin emergency query expects
    console.log('\n3️⃣ Analyzing admin emergency query requirements...');
    console.log('Expected columns from admin emergency query:');
    console.log('   • er.id');
    console.log('   • er.patient_id');
    console.log('   • er.emergency_date');
    console.log('   • er.emergency_type');
    console.log('   • er.description');
    console.log('   • er.severity');
    console.log('   • er.resolved');
    console.log('   • er.status');
    console.log('   • er.priority');
    console.log('   • er.handled_by');
    console.log('   • er.resolution');
    console.log('   • er.follow_up_required');
    console.log('   • er.resolved_at');
    console.log('   • er.emergency_contact');
    console.log('   • er.notes');
    console.log('   • er.created_at');

    // Step 4: Compare with current schema
    console.log('\n4️⃣ Current schema from setup_railway_db.js:');
    console.log('   • id UUID PRIMARY KEY');
    console.log('   • patient_id UUID REFERENCES patients(id)');
    console.log('   • emergency_date TIMESTAMP');
    console.log('   • emergency_type VARCHAR(100)');
    console.log('   • description TEXT');
    console.log('   • severity VARCHAR(20)');
    console.log('   • resolved BOOLEAN DEFAULT false');
    console.log('   • created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP');

    console.log('\n5️⃣ Missing columns:');
    console.log('   • status');
    console.log('   • priority');
    console.log('   • handled_by');
    console.log('   • resolution');
    console.log('   • follow_up_required');
    console.log('   • resolved_at');
    console.log('   • emergency_contact');
    console.log('   • notes');

    console.log('\n📋 SCHEMA ANALYSIS SUMMARY:');
    console.log('   • Admin authentication: ✅');
    console.log('   • Emergency table exists: ⚠️ (basic schema)');
    console.log('   • Missing columns: ❌ (8 columns missing)');
    console.log('   • Admin emergency query: ❌ (will fail due to missing columns)');
    console.log('   • Emergency creation: ⚠️ (may work with basic schema)');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testEmergencyTableSchema(); 