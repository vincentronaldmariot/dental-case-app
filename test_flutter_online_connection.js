const axios = require('axios');

async function testFlutterOnlineConnection() {
  try {
    console.log('🧪 Testing Flutter app connection to online server...');
    
    const onlineUrl = 'https://afp-dental-app-production.up.railway.app';
    
    // Step 1: Login as admin (exactly like Flutter app does)
    console.log('📝 Step 1: Admin login...');
    const adminLoginResponse = await axios.post(`${onlineUrl}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');
    
    // Step 2: Fetch pending appointments (exactly like Flutter app does)
    console.log('\n📝 Step 2: Fetching pending appointments...');
    const pendingResponse = await axios.get(`${onlineUrl}/api/admin/appointments/pending`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Pending appointments response:');
    console.log('📊 Status:', pendingResponse.status);
    console.log('📊 Response type:', typeof pendingResponse.data);
    console.log('📊 Is array:', Array.isArray(pendingResponse.data));
    console.log('📊 Has pendingAppointments key:', pendingResponse.data.hasOwnProperty('pendingAppointments'));
    
    if (pendingResponse.data.hasOwnProperty('pendingAppointments')) {
      const appointments = pendingResponse.data.pendingAppointments;
      console.log('📊 Total pending appointments:', appointments.length);
      
      if (appointments.length > 0) {
        console.log('📋 Pending appointments:');
        appointments.forEach((apt, index) => {
          console.log(`  ${index + 1}. ${apt.patientName} - ${apt.service} - ${apt.appointmentDate} ${apt.timeSlot}`);
          console.log(`     ID: ${apt.id}, Status: ${apt.status}`);
        });
      } else {
        console.log('❌ No pending appointments found');
      }
    } else {
      console.log('❌ Response does not have pendingAppointments key');
      console.log('📊 Full response:', JSON.stringify(pendingResponse.data, null, 2));
    }
    
    // Step 3: Test creating a new appointment as a patient
    console.log('\n📝 Step 3: Creating new appointment as patient...');
    
    // Login as patient
    const patientLoginResponse = await axios.post(`${onlineUrl}/api/auth/login`, {
      email: 'john.doe@test.com',
      password: 'password123'
    });
    
    const patientToken = patientLoginResponse.data.token;
    console.log('✅ Patient login successful');
    
    // Create appointment
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 3);
    const appointmentDate = tomorrow.toISOString().split('T')[0];
    
    const bookingResponse = await axios.post(`${onlineUrl}/api/appointments`, {
      service: 'Dental Cleaning',
      appointmentDate: appointmentDate,
      timeSlot: '2:00 PM',
      notes: 'Test appointment from Flutter simulation'
    }, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ New appointment created:', bookingResponse.data.appointment.id);
    
    // Step 4: Check pending appointments again
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
        });
      }
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

testFlutterOnlineConnection(); 