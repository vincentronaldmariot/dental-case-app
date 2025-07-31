const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testEmergencySystem() {
  console.log('🔍 Comprehensive Emergency System Check\n');

  try {
    // Step 1: Test admin login
    console.log('1️⃣ Testing admin login...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');
    console.log(`   Token: ${adminToken.substring(0, 20)}...`);

    // Step 2: Test emergency records endpoint
    console.log('\n2️⃣ Testing emergency records endpoint...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });
      
      console.log('✅ Emergency records endpoint working');
      console.log(`   Records found: ${emergencyResponse.data.length || 0}`);
      
      if (emergencyResponse.data.length > 0) {
        console.log('   Sample record structure:');
        console.log('   ', JSON.stringify(emergencyResponse.data[0], null, 2));
      }
    } catch (error) {
      console.log('❌ Emergency records endpoint failed:');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
    }

    // Step 3: Test emergency statistics endpoint
    console.log('\n3️⃣ Testing emergency statistics endpoint...');
    try {
      const statsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency/stats`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });
      
      console.log('✅ Emergency statistics endpoint working');
      console.log('   Stats:', statsResponse.data);
    } catch (error) {
      console.log('❌ Emergency statistics endpoint failed:');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
    }

    // Step 4: Test patient login for emergency creation
    console.log('\n4️⃣ Testing patient login for emergency creation...');
    try {
      const patientLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
        email: 'rolex@gmail.com',
        password: 'password123'
      });
      
      const patientToken = patientLoginResponse.data.token;
      const patientId = patientLoginResponse.data.patient.id;
      console.log('✅ Patient login successful');
      console.log(`   Patient ID: ${patientId}`);

      // Step 5: Test emergency creation
      console.log('\n5️⃣ Testing emergency record creation...');
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

      // Step 6: Test emergency status update
      console.log('\n6️⃣ Testing emergency status update...');
      try {
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
      } catch (error) {
        console.log('❌ Emergency status update failed:');
        console.log(`   Status: ${error.response?.status}`);
        console.log(`   Error: ${error.response?.data?.error || error.message}`);
      }

      // Step 7: Test emergency notification
      console.log('\n7️⃣ Testing emergency notification...');
      try {
        const notifyResponse = await axios.post(`${ONLINE_SERVER_URL}/api/admin/emergencies/${emergencyId}/notify`, {
          message: 'Your emergency appointment has been scheduled for tomorrow at 2:00 PM'
        }, {
          headers: {
            'Authorization': `Bearer ${adminToken}`,
            'Content-Type': 'application/json'
          }
        });
        
        console.log('✅ Emergency notification sent successfully');
        console.log('   Notification:', notifyResponse.data);
      } catch (error) {
        console.log('❌ Emergency notification failed:');
        console.log(`   Status: ${error.response?.status}`);
        console.log(`   Error: ${error.response?.data?.error || error.message}`);
      }

      // Step 8: Test emergency deletion
      console.log('\n8️⃣ Testing emergency record deletion...');
      try {
        const deleteResponse = await axios.delete(`${ONLINE_SERVER_URL}/api/admin/emergencies/${emergencyId}`, {
          headers: {
            'Authorization': `Bearer ${adminToken}`
          }
        });
        
        console.log('✅ Emergency record deleted successfully');
        console.log('   Response:', deleteResponse.data);
      } catch (error) {
        console.log('❌ Emergency record deletion failed:');
        console.log(`   Status: ${error.response?.status}`);
        console.log(`   Error: ${error.response?.data?.error || error.message}`);
      }

    } catch (error) {
      console.log('❌ Patient login failed:');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
    }

    // Step 9: Test database schema directly
    console.log('\n9️⃣ Testing database schema...');
    try {
      const schemaResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/database/schema`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      });
      
      console.log('✅ Database schema endpoint working');
      console.log('   Schema:', schemaResponse.data);
    } catch (error) {
      console.log('❌ Database schema endpoint failed (this is expected if not implemented):');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
    }

  } catch (error) {
    console.log('❌ Test failed:', error.message);
  }

  console.log('\n📋 SUMMARY:');
  console.log('If you see 500 errors, the database schema needs to be updated.');
  console.log('If you see 404 errors, the backend endpoints need to be deployed.');
  console.log('If you see 403 errors, there are authentication issues.');
  console.log('\n🔧 NEXT STEPS:');
  console.log('1. Check the EMERGENCY_TAB_FIX_GUIDE.md for manual database updates');
  console.log('2. Deploy backend changes to Railway');
  console.log('3. Test the Flutter app admin emergencies tab');
}

testEmergencySystem().catch(console.error); 