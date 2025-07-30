const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testPatientCompletedTabFocused() {
  try {
    console.log('🔍 Focused Test: Patient Completed Tab...\n');

    // Step 1: Login as a patient
    console.log('1️⃣ Logging in as patient...');
    const loginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'rolex@gmail.com',
      password: 'password123'
    });

    const patientId = loginResponse.data.patient.id;
    const patientToken = loginResponse.data.token;
    console.log(`✅ Patient logged in: ${patientId}`);

    // Step 2: Check notifications for appointment_completed type
    console.log('\n2️⃣ Checking for appointment_completed notifications...');
    const notificationsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/notifications`, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });

    const notifications = notificationsResponse.data.notifications || [];
    console.log(`📱 Total notifications: ${notifications.length}`);

    // Check for appointment_completed notifications
    const completedNotifications = notifications.filter(n => n.type === 'appointment_completed');
    const approvedNotifications = notifications.filter(n => n.type === 'appointment_approved');
    
    console.log(`✅ appointment_completed notifications: ${completedNotifications.length}`);
    console.log(`✅ appointment_approved notifications: ${approvedNotifications.length}`);

    if (completedNotifications.length === 0) {
      console.log('\n⚠️ No appointment_completed notifications found!');
      console.log('   This means the backend is not sending completion notifications.');
      console.log('   The patient will only see "Scheduled" appointments, not "Completed".');
    }

    // Step 3: Test our fallback logic
    console.log('\n3️⃣ Testing fallback logic with current notifications...');
    const appointmentNotifications = notifications.filter(notification => {
      return notification.type === 'appointment_approved' || 
             notification.type === 'appointment_completed';
    });

    console.log(`🔍 Appointment notifications to process: ${appointmentNotifications.length}`);

    // Simulate the fallback logic
    const inferredAppointments = [];
    for (const notification of appointmentNotifications) {
      const message = notification.message;
      
      // Service regex
      const serviceRegex = /for (.+?) on/;
      const serviceMatch = message.match(serviceRegex);
      
      // Date regex
      const dateRegex = /on (\d{1,2}\/\d{1,2}\/\d{4})/;
      const dateMatch = message.match(dateRegex);
      
      // Time regex
      const timeRegex = /at (\d{1,2}:\d{2}(?: [AP]M)?)/;
      const timeMatch = message.match(timeRegex);

      if (serviceMatch && dateMatch) {
        const service = serviceMatch[1];
        const dateStr = dateMatch[1];
        const timeSlot = timeMatch ? timeMatch[1] : '';

        // Determine status based on notification type
        let appointmentStatus = 'approved';
        if (notification.type === 'appointment_completed') {
          appointmentStatus = 'completed';
        }

        inferredAppointments.push({
          id: `inferred_${notification.id}`,
          service: service,
          date: dateStr,
          time_slot: timeSlot,
          status: appointmentStatus,
          notification_type: notification.type
        });

        console.log(`✅ Inferred: ${service} on ${dateStr} at ${timeSlot} (${appointmentStatus})`);
      }
    }

    // Step 4: Summary
    console.log('\n📊 SUMMARY:');
    console.log(`   • Total notifications: ${notifications.length}`);
    console.log(`   • appointment_completed: ${completedNotifications.length}`);
    console.log(`   • appointment_approved: ${approvedNotifications.length}`);
    console.log(`   • Inferred appointments: ${inferredAppointments.length}`);
    
    const completedCount = inferredAppointments.filter(apt => apt.status === 'completed').length;
    const approvedCount = inferredAppointments.filter(apt => apt.status === 'approved').length;
    
    console.log(`   • Will show as completed: ${completedCount}`);
    console.log(`   • Will show as scheduled: ${approvedCount}`);

    if (completedCount > 0) {
      console.log('\n✅ Patient should see completed appointments in the "Completed" tab');
    } else {
      console.log('\n⚠️ No completed appointments will be shown');
      console.log('   Reason: No appointment_completed notifications from backend');
      console.log('   Solution: Backend needs to send appointment_completed notifications');
    }

    // Step 5: Show what the patient will actually see
    console.log('\n👤 What the patient will see:');
    if (approvedCount > 0) {
      console.log(`   • Scheduled tab: ${approvedCount} appointments`);
    }
    if (completedCount > 0) {
      console.log(`   • Completed tab: ${completedCount} appointments`);
    }
    if (completedCount === 0 && approvedCount === 0) {
      console.log('   • No appointments visible');
    }

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testPatientCompletedTabFocused(); 