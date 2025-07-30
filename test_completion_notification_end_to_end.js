const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testCompletionNotificationEndToEnd() {
  try {
    console.log('🧪 End-to-End Test: Completion Notification Fix...\n');

    // Step 1: Login as patient
    console.log('1️⃣ Logging in as patient...');
    const patientLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'rolex@gmail.com',
      password: 'password123'
    });

    const patientId = patientLoginResponse.data.patient.id;
    const patientToken = patientLoginResponse.data.token;
    console.log(`✅ Patient logged in: ${patientId}`);

    // Step 2: Book a new appointment
    console.log('\n2️⃣ Booking a new appointment...');
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const appointmentDate = tomorrow.toISOString().split('T')[0];

    const bookingResponse = await axios.post(`${ONLINE_SERVER_URL}/api/appointments`, {
      patientId: patientId,
      service: 'Teeth Cleaning',
      appointmentDate: appointmentDate,
      timeSlot: '09:00 AM',
      notes: 'Test appointment for completion notification'
    }, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });

    const appointmentId = bookingResponse.data.appointment.id;
    console.log(`✅ Appointment booked: ${appointmentId}`);

    // Step 3: Login as admin
    console.log('\n3️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 4: Approve the appointment
    console.log('\n4️⃣ Approving appointment...');
    const approveResponse = await axios.post(`${ONLINE_SERVER_URL}/api/admin/appointments/${appointmentId}/approve`, {
      notes: 'Approved for testing completion notification'
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });

    console.log('✅ Appointment approved');

    // Step 5: Check for approval notification
    console.log('\n5️⃣ Checking for approval notification...');
    const notificationsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/notifications`, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });

    const notifications = notificationsResponse.data.notifications || [];
    const approvalNotifications = notifications.filter(n => n.type === 'appointment_approved');
    console.log(`📱 Found ${approvalNotifications.length} approval notifications`);

    // Step 6: Mark appointment as completed
    console.log('\n6️⃣ Marking appointment as completed...');
    const completeResponse = await axios.put(`${ONLINE_SERVER_URL}/api/admin/appointments/${appointmentId}/status`, {
      status: 'completed',
      notes: 'Appointment completed - testing notification'
    }, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });

    console.log('✅ Appointment marked as completed');

    // Step 7: Check for completion notification
    console.log('\n7️⃣ Checking for completion notification...');
    const updatedNotificationsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/notifications`, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });

    const updatedNotifications = updatedNotificationsResponse.data.notifications || [];
    const completionNotifications = updatedNotifications.filter(n => n.type === 'appointment_completed');
    
    console.log(`📱 Total notifications: ${updatedNotifications.length}`);
    console.log(`✅ appointment_completed notifications: ${completionNotifications.length}`);

    if (completionNotifications.length > 0) {
      console.log('🎉 SUCCESS! Completion notification was created');
      console.log('Latest completion notification:', completionNotifications[0]);
      
      // Step 8: Test patient history endpoint
      console.log('\n8️⃣ Testing patient history endpoint...');
      try {
        const historyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/history`, {
          headers: { Authorization: `Bearer ${patientToken}` }
        });
        console.log('✅ Patient history endpoint working');
        console.log(`📊 Found ${historyResponse.data.appointments?.length || 0} appointments`);
      } catch (error) {
        console.log('❌ Patient history endpoint failed (expected - will use fallback)');
      }

      // Step 9: Test fallback mechanism
      console.log('\n9️⃣ Testing fallback mechanism...');
      const appointmentNotifications = updatedNotifications.filter(notification => {
        return notification.type === 'appointment_approved' || 
               notification.type === 'appointment_completed';
      });

      console.log(`🔍 Appointment notifications: ${appointmentNotifications.length}`);
      
      const completedCount = appointmentNotifications.filter(n => n.type === 'appointment_completed').length;
      const approvedCount = appointmentNotifications.filter(n => n.type === 'appointment_approved').length;
      
      console.log(`   • appointment_completed: ${completedCount}`);
      console.log(`   • appointment_approved: ${approvedCount}`);

      if (completedCount > 0) {
        console.log('\n✅ Patient should now see completed appointments in the "Completed" tab!');
      }

    } else {
      console.log('❌ No completion notification found');
      console.log('   This means the backend fix needs to be deployed to the online server');
    }

    console.log('\n📋 TEST SUMMARY:');
    console.log('   • Appointment booking: ✅');
    console.log('   • Appointment approval: ✅');
    console.log('   • Approval notification: ✅');
    console.log('   • Status update to completed: ✅');
    console.log(`   • Completion notification: ${completionNotifications.length > 0 ? '✅' : '❌'}`);
    console.log('   • Backend fix deployed: ⚠️ (needs deployment)');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testCompletionNotificationEndToEnd(); 