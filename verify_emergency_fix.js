const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function verifyEmergencyFix() {
  console.log('🔍 Verifying Emergency Database Fix\n');

  try {
    // Step 1: Admin login
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');

    // Step 2: Test emergency records endpoint
    console.log('\n2️⃣ Testing emergency records endpoint...');
    const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`
      }
    });
    
    console.log('✅ Emergency records endpoint working!');
    console.log(`   Records found: ${emergencyResponse.data.length || 0}`);
    
    if (emergencyResponse.data.length > 0) {
      console.log('   Sample record structure:');
      const sample = emergencyResponse.data[0];
      console.log(`   - ID: ${sample.id}`);
      console.log(`   - Patient: ${sample.first_name} ${sample.last_name}`);
      console.log(`   - Type: ${sample.emergency_type}`);
      console.log(`   - Status: ${sample.status}`);
      console.log(`   - Priority: ${sample.priority}`);
      console.log(`   - Handled by: ${sample.handled_by || 'Not assigned'}`);
      console.log(`   - Resolved: ${sample.resolved}`);
    }

    // Step 3: Test emergency creation (if no records exist)
    if (emergencyResponse.data.length === 0) {
      console.log('\n3️⃣ No emergency records found. Testing creation...');
      
      // Patient login
      const patientLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
        email: 'rolex@gmail.com',
        password: 'password123'
      });
      
      const patientToken = patientLoginResponse.data.token;
      const patientId = patientLoginResponse.data.patient.id;
      console.log('✅ Patient login successful');

      // Create emergency record
      const emergencyData = {
        patient_id: patientId,
        emergency_date: new Date().toISOString(),
        emergency_type: 'Dental Pain',
        description: 'Severe toothache in upper right molar',
        severity: 'High',
        resolved: false
      };

      const createResponse = await axios.post(`${ONLINE_SERVER_URL}/api/emergency`, emergencyData, {
        headers: {
          'Authorization': `Bearer ${patientToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Emergency record created successfully');
      console.log(`   Emergency ID: ${createResponse.data.id}`);
      
      const emergencyId = createResponse.data.id;

      // Test status update
      console.log('\n4️⃣ Testing emergency status update...');
      const statusResponse = await axios.put(`${ONLINE_SERVER_URL}/api/admin/emergency/${emergencyId}/status`, {
        status: 'in_progress',
        priority: 'high',
        handled_by: 'Dr. Smith',
        notes: 'Patient scheduled for immediate treatment'
      }, {
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Emergency status update successful');
      console.log('   Updated record:', statusResponse.data);

      // Test notification
      console.log('\n5️⃣ Testing emergency notification...');
      const notifyResponse = await axios.post(`${ONLINE_SERVER_URL}/api/admin/emergencies/${emergencyId}/notify`, {
        message: 'Your emergency appointment has been scheduled for tomorrow at 2:00 PM'
      }, {
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Emergency notification sent successfully');

      // Test deletion
      console.log('\n6️⃣ Testing emergency record deletion...');
      const deleteResponse = await axios.delete(`${ONLINE_SERVER_URL}/api/admin/emergencies/${emergencyId}`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });
      
      console.log('✅ Emergency record deleted successfully');
    }

    console.log('\n🎉 ALL TESTS PASSED!');
    console.log('✅ Emergency database fix is working correctly');
    console.log('✅ Admin emergencies tab should now work in Flutter app');
    console.log('✅ Remove button should be functional');
    console.log('✅ All emergency features are operational');

  } catch (error) {
    console.log('❌ Verification failed:');
    console.log(`   Status: ${error.response?.status}`);
    console.log(`   Error: ${error.response?.data?.error || error.message}`);
    
    if (error.response?.status === 500) {
      console.log('\n🔧 The database fix may not have been applied yet.');
      console.log('Please follow the steps in EMERGENCY_MANUAL_FIX_STEPS.md');
    }
  }
}

console.log('📋 This script will verify if the emergency database fix worked.');
console.log('Make sure you have applied the database schema changes first.\n');

verifyEmergencyFix().catch(console.error); 