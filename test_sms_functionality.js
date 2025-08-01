const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testSMSFunctionality() {
  try {
    console.log('🔍 Testing SMS Functionality...\n');

    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 2: Check SMS service status
    console.log('\n2️⃣ Checking SMS service status...');
    try {
      const smsStatusResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/sms-status`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const smsStatus = smsStatusResponse.data.smsStatus;
      console.log('📊 SMS Service Status:');
      console.log(`   - Configured: ${smsStatus.configured}`);
      console.log(`   - Account SID: ${smsStatus.accountSid}`);
      console.log(`   - Auth Token: ${smsStatus.authToken}`);
      console.log(`   - Phone Number: ${smsStatus.phoneNumber}`);

      if (smsStatus.configured) {
        console.log('✅ SMS service is properly configured');
      } else {
        console.log('⚠️ SMS service is not configured - SMS will not be sent');
      }
    } catch (error) {
      console.log('❌ Failed to get SMS status');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
    }

    // Step 3: Test emergency notification with SMS
    console.log('\n3️⃣ Testing emergency notification with SMS...');
    try {
      // First get emergency records to find one to test with
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/emergency-admin`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const emergencyRecords = emergencyResponse.data || [];
      
      if (emergencyRecords.length > 0) {
        const testEmergency = emergencyRecords[0];
        console.log(`📋 Testing with emergency record: ${testEmergency.id}`);

        const notificationResponse = await axios.post(
          `${ONLINE_SERVER_URL}/api/admin/emergencies/${testEmergency.id}/notify`,
          {
            patientId: testEmergency.patientId,
            message: 'Test SMS notification from admin dashboard',
            emergencyType: testEmergency.emergencyTypeDisplay
          },
          {
            headers: { Authorization: `Bearer ${adminToken}` }
          }
        );

        console.log('✅ Emergency notification sent successfully');
        console.log('📊 Response:', JSON.stringify(notificationResponse.data, null, 2));
      } else {
        console.log('⚠️ No emergency records found to test with');
      }
    } catch (error) {
      console.log('❌ Emergency notification test failed');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
    }

    // Step 4: Test patient notifications endpoint
    console.log('\n4️⃣ Testing patient notifications endpoint...');
    try {
      // Get a patient to test with
      const patientsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const patients = patientsResponse.data || [];
      
      if (patients.length > 0) {
        const testPatient = patients[0];
        console.log(`📋 Testing with patient: ${testPatient.firstName} ${testPatient.lastName}`);

        // Login as patient to test notifications
        const patientLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
          email: testPatient.email,
          password: 'password123' // Assuming default password
        });

        if (patientLoginResponse.data.token) {
          const patientToken = patientLoginResponse.data.token;
          
          const notificationsResponse = await axios.get(
            `${ONLINE_SERVER_URL}/api/patients/${testPatient.id}/notifications`,
            {
              headers: { Authorization: `Bearer ${patientToken}` }
            }
          );

          const notifications = notificationsResponse.data.notifications || [];
          console.log(`📊 Found ${notifications.length} notifications for patient`);
          
          // Look for SMS-related notifications
          const smsNotifications = notifications.filter(n => n.smsSent);
          console.log(`📱 Found ${smsNotifications.length} notifications with SMS sent`);
          
          if (smsNotifications.length > 0) {
            console.log('📋 SMS notifications:');
            smsNotifications.forEach((notification, index) => {
              console.log(`   ${index + 1}. ${notification.title}: ${notification.message}`);
              console.log(`      SMS Message ID: ${notification.smsMessageId}`);
            });
          }
        } else {
          console.log('⚠️ Could not login as patient to test notifications');
        }
      } else {
        console.log('⚠️ No patients found to test with');
      }
    } catch (error) {
      console.log('❌ Patient notifications test failed');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
    }

    console.log('\n📋 SMS FUNCTIONALITY SUMMARY:');
    console.log('   • Admin authentication: ✅');
    console.log('   • SMS service status check: ⚠️ (needs verification)');
    console.log('   • Emergency notification with SMS: ⚠️ (needs verification)');
    console.log('   • Patient notifications with SMS tracking: ⚠️ (needs verification)');

  } catch (error) {
    console.log('❌ Test failed:', error.message);
  }
}

testSMSFunctionality(); 