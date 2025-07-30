const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testPatientCompletedTab() {
  try {
    console.log('🔍 Testing Patient Completed Tab Functionality...\n');

    // Step 1: Login as a patient
    console.log('1️⃣ Logging in as patient...');
    const loginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'rolex@gmail.com',
      password: 'password123'
    });

    const patientId = loginResponse.data.patient.id;
    const patientToken = loginResponse.data.token;
    console.log(`✅ Patient logged in: ${patientId}`);

    // Step 2: Check patient history endpoint
    console.log('\n2️⃣ Testing patient history endpoint...');
    try {
      const historyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/history`, {
        headers: { Authorization: `Bearer ${patientToken}` }
      });
      console.log('✅ Patient history endpoint working');
      console.log(`📊 Found ${historyResponse.data.appointments?.length || 0} appointments`);
      
      if (historyResponse.data.appointments?.length > 0) {
        const statuses = historyResponse.data.appointments.map(apt => apt.status);
        console.log(`📋 Appointment statuses: ${statuses.join(', ')}`);
      }
    } catch (error) {
      console.log('❌ Patient history endpoint failed (expected - this triggers fallback)');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    // Step 3: Check notifications
    console.log('\n3️⃣ Checking patient notifications...');
    const notificationsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/notifications`, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });

    const notifications = notificationsResponse.data.notifications || [];
    console.log(`📱 Found ${notifications.length} notifications`);

    // Group notifications by type
    const notificationTypes = {};
    notifications.forEach(notification => {
      const type = notification.type;
      if (!notificationTypes[type]) {
        notificationTypes[type] = [];
      }
      notificationTypes[type].push(notification);
    });

    console.log('\n📋 Notification types found:');
    Object.keys(notificationTypes).forEach(type => {
      console.log(`   ${type}: ${notificationTypes[type].length} notifications`);
    });

    // Step 4: Test fallback mechanism
    console.log('\n4️⃣ Testing fallback appointment inference...');
    const appointmentNotifications = notifications.filter(notification => {
      return notification.type === 'appointment_approved' || 
             notification.type === 'appointment_completed';
    });

    console.log(`🔍 Found ${appointmentNotifications.length} appointment-related notifications`);

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

        // Parse date
        const dateParts = dateStr.split('/');
        const month = parseInt(dateParts[0], 10);
        const day = parseInt(dateParts[1], 10);
        const year = parseInt(dateParts[2], 10);
        const date = new Date(year, month - 1, day);

        // Determine status based on notification type
        let appointmentStatus = 'approved';
        if (notification.type === 'appointment_completed') {
          appointmentStatus = 'completed';
        }

        inferredAppointments.push({
          id: `inferred_${notification.id}`,
          patient_id: patientId,
          service: service,
          date: date.toISOString(),
          time_slot: timeSlot,
          status: appointmentStatus,
          notes: '',
          created_at: notification.createdAt,
        });

        console.log(`✅ Inferred: ${service} on ${dateStr} at ${timeSlot} (${appointmentStatus})`);
      }
    }

    // Step 5: Check admin view of patient appointments
    console.log('\n5️⃣ Testing admin view of patient appointments...');
    
    // Login as admin
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'admin@dental.com',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Get patient appointments as admin
    const adminAppointmentsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${patientId}/appointments`, {
      headers: { Authorization: `Bearer ${adminToken}` }
    });

    const adminAppointments = adminAppointmentsResponse.data.appointments || [];
    console.log(`📊 Admin sees ${adminAppointments.length} appointments for this patient`);

    if (adminAppointments.length > 0) {
      const adminStatuses = adminAppointments.map(apt => apt.status);
      console.log(`📋 Admin appointment statuses: ${adminStatuses.join(', ')}`);
    }

    // Step 6: Summary
    console.log('\n📊 SUMMARY:');
    console.log(`   • Patient history endpoint: ${historyResponse ? '✅ Working' : '❌ Failed (triggers fallback)'}`);
    console.log(`   • Notifications found: ${notifications.length}`);
    console.log(`   • Appointment notifications: ${appointmentNotifications.length}`);
    console.log(`   • Inferred appointments: ${inferredAppointments.length}`);
    console.log(`   • Admin sees appointments: ${adminAppointments.length}`);
    
    const completedCount = inferredAppointments.filter(apt => apt.status === 'completed').length;
    const approvedCount = inferredAppointments.filter(apt => apt.status === 'approved').length;
    
    console.log(`   • Inferred completed: ${completedCount}`);
    console.log(`   • Inferred approved: ${approvedCount}`);

    if (completedCount > 0) {
      console.log('\n✅ Patient should see completed appointments in the "Completed" tab');
    } else {
      console.log('\n⚠️ No completed appointments found - patient may not see "Completed" tab');
    }

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}



testPatientCompletedTab(); 