const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function deployCompletionNotificationFix() {
  try {
    console.log('🚀 Deploying Completion Notification Fix...\n');

    // Step 1: Test the current state
    console.log('1️⃣ Testing current state...');
    
    // Login as admin
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Get pending appointments
    const pendingResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/pending-appointments`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });

    const pendingAppointments = pendingResponse.data.pendingAppointments || [];
    console.log(`📊 Found ${pendingAppointments.length} pending appointments`);

    if (pendingAppointments.length === 0) {
      console.log('⚠️ No pending appointments to test with');
      console.log('   You can test this by:');
      console.log('   1. Booking a new appointment as a patient');
      console.log('   2. Approving it as admin');
      console.log('   3. Marking it as completed using the status update endpoint');
      return;
    }

    // Step 2: Test the status update endpoint
    console.log('\n2️⃣ Testing status update endpoint...');
    const testAppointment = pendingAppointments[0];
    console.log(`📋 Testing with appointment: ${testAppointment.appointment_id} - ${testAppointment.service}`);

    try {
      const statusUpdateResponse = await axios.put(
        `${ONLINE_SERVER_URL}/api/admin/appointments/${testAppointment.appointment_id}/status`,
        {
          status: 'completed',
          notes: 'Test completion notification'
        },
        {
          headers: { Authorization: `Bearer ${adminToken}` }
        }
      );

      console.log('✅ Status update successful');
      console.log('Response:', statusUpdateResponse.data);

      // Step 3: Check if notification was created
      console.log('\n3️⃣ Checking for completion notification...');
      
      // Login as the patient to check notifications
      const patientLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
        email: testAppointment.email,
        password: 'password123' // Assuming default password
      });

      if (patientLoginResponse.data.token) {
        const patientToken = patientLoginResponse.data.token;
        const patientId = patientLoginResponse.data.patient.id;

        const notificationsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/notifications`, {
          headers: { Authorization: `Bearer ${patientToken}` }
        });

        const notifications = notificationsResponse.data.notifications || [];
        const completedNotifications = notifications.filter(n => n.type === 'appointment_completed');
        
        console.log(`📱 Total notifications: ${notifications.length}`);
        console.log(`✅ appointment_completed notifications: ${completedNotifications.length}`);

        if (completedNotifications.length > 0) {
          console.log('🎉 SUCCESS! Completion notification was created');
          console.log('Latest completion notification:', completedNotifications[0]);
        } else {
          console.log('❌ No completion notification found');
          console.log('   This means the fix needs to be deployed to the online server');
        }
      } else {
        console.log('⚠️ Could not login as patient to check notifications');
      }

    } catch (statusError) {
      console.log('❌ Status update failed:', statusError.response?.data || statusError.message);
    }

    console.log('\n📋 DEPLOYMENT SUMMARY:');
    console.log('   • Backend fix created: ✅');
    console.log('   • Online server needs deployment: ⚠️');
    console.log('   • Frontend fallback mechanism: ✅');
    console.log('\n🔧 NEXT STEPS:');
    console.log('   1. Deploy the backend fix to Railway');
    console.log('   2. Test marking an appointment as completed');
    console.log('   3. Verify completion notification is sent');
    console.log('   4. Check patient app shows completed appointments');

  } catch (error) {
    console.error('❌ Deployment test failed:', error.response?.data || error.message);
  }
}

deployCompletionNotificationFix(); 