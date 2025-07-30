const axios = require('axios');

async function testAdminDashboardPending() {
  try {
    console.log('🧪 Testing Admin Dashboard Pending Appointments...');
    
    const onlineUrl = 'https://afp-dental-app-production.up.railway.app';
    
    // Step 1: Login as admin
    console.log('📝 Step 1: Admin login...');
    const adminLoginResponse = await axios.post(`${onlineUrl}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');
    
    // Step 2: Check current pending appointments
    console.log('\n📝 Step 2: Checking current pending appointments...');
    const pendingResponse = await axios.get(`${onlineUrl}/api/admin/appointments/pending`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Pending appointments response:');
    console.log('📊 Status:', pendingResponse.status);
    console.log('📊 Response type:', typeof pendingResponse.data);
    console.log('📊 Has pendingAppointments key:', pendingResponse.data.hasOwnProperty('pendingAppointments'));
    
    if (pendingResponse.data.hasOwnProperty('pendingAppointments')) {
      const appointments = pendingResponse.data.pendingAppointments;
      console.log('📊 Total pending appointments:', appointments.length);
      
      if (appointments.length > 0) {
        console.log('📋 Current pending appointments:');
        appointments.forEach((apt, index) => {
          console.log(`  ${index + 1}. ${apt.patientName} - ${apt.service} - ${apt.appointmentDate} ${apt.timeSlot}`);
          console.log(`     ID: ${apt.id}, Status: ${apt.status}`);
          console.log(`     Has Survey: ${apt.hasSurveyData}`);
          console.log(`     Patient Email: ${apt.patientEmail}`);
          console.log(`     Patient Phone: ${apt.patientPhone}`);
        });
      } else {
        console.log('❌ No pending appointments found');
      }
    }
    
    // Step 3: Create a new appointment to test real-time updates
    console.log('\n📝 Step 3: Creating new appointment to test real-time updates...');
    
    // Login as patient
    const patientLoginResponse = await axios.post(`${onlineUrl}/api/auth/login`, {
      email: 'jane.smith@test.com',
      password: 'password123'
    });
    
    const patientToken = patientLoginResponse.data.token;
    console.log('✅ Patient login successful');
    
    // Create appointment
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const appointmentDate = tomorrow.toISOString().split('T')[0];
    
    const bookingResponse = await axios.post(`${onlineUrl}/api/appointments`, {
      service: 'Dental Cleaning',
      appointmentDate: appointmentDate,
      timeSlot: '3:00 PM',
      notes: 'Test appointment for admin dashboard'
    }, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ New appointment created:', bookingResponse.data.appointment.id);
    
    // Step 4: Check pending appointments again immediately
    console.log('\n📝 Step 4: Checking pending appointments after new booking...');
    const newPendingResponse = await axios.get(`${onlineUrl}/api/admin/appointments/pending`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    if (newPendingResponse.data.hasOwnProperty('pendingAppointments')) {
      const newAppointments = newPendingResponse.data.pendingAppointments;
      console.log('✅ Updated pending appointments:');
      console.log('📊 Total pending appointments:', newAppointments.length);
      
      if (newAppointments.length > 0) {
        console.log('📋 All pending appointments:');
        newAppointments.forEach((apt, index) => {
          console.log(`  ${index + 1}. ${apt.patientName} - ${apt.service} - ${apt.appointmentDate} ${apt.timeSlot}`);
          console.log(`     ID: ${apt.id}, Status: ${apt.status}`);
          console.log(`     Has Survey: ${apt.hasSurveyData}`);
        });
        
        // Check if the new appointment is in the list
        const newAppointmentId = bookingResponse.data.appointment.id;
        const foundAppointment = newAppointments.find(apt => apt.id === newAppointmentId);
        
        if (foundAppointment) {
          console.log('✅ New appointment found in pending list!');
        } else {
          console.log('❌ New appointment NOT found in pending list!');
        }
      }
    }
    
    // Step 5: Test the alternative pending appointments endpoint
    console.log('\n📝 Step 5: Testing alternative pending appointments endpoint...');
    const altPendingResponse = await axios.get(`${onlineUrl}/api/admin/pending-appointments`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Alternative endpoint response:');
    console.log('📊 Status:', altPendingResponse.status);
    console.log('📊 Response type:', typeof altPendingResponse.data);
    console.log('📊 Is array:', Array.isArray(altPendingResponse.data));
    console.log('📊 Total appointments:', altPendingResponse.data.length);
    
    if (Array.isArray(altPendingResponse.data) && altPendingResponse.data.length > 0) {
      console.log('📋 Alternative endpoint appointments:');
      altPendingResponse.data.forEach((apt, index) => {
        console.log(`  ${index + 1}. ${apt.patient_name} - ${apt.service} - ${apt.booking_date} ${apt.time_slot}`);
        console.log(`     ID: ${apt.appointment_id}, Status: ${apt.status}`);
      });
    }
    
  } catch (error) {
    console.error('❌ Test failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
  }
}

testAdminDashboardPending(); 