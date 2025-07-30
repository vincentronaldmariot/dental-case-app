const axios = require('axios');

async function testOnlineServer() {
  try {
    console.log('🧪 Testing online Railway server...');
    
    const onlineUrl = 'https://afp-dental-app-production.up.railway.app';
    
    // Step 1: Test server health
    console.log('📝 Step 1: Testing server health...');
    try {
      const healthResponse = await axios.get(`${onlineUrl}/health`);
      console.log('✅ Server health check:', healthResponse.status);
    } catch (healthError) {
      console.log('⚠️ Health check failed:', healthError.message);
    }
    
    // Step 2: Login as admin
    console.log('\n📝 Step 2: Logging in as admin...');
    const adminLoginResponse = await axios.post(`${onlineUrl}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');
    
    // Step 3: Test pending appointments endpoint
    console.log('\n📝 Step 3: Testing pending appointments endpoint...');
    const pendingResponse = await axios.get(`${onlineUrl}/api/admin/appointments/pending`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Online pending appointments response:');
    console.log('📊 Status:', pendingResponse.status);
    console.log('📊 Total pending appointments:', pendingResponse.data.length);
    
    if (pendingResponse.data.length > 0) {
      console.log('📋 Pending appointments:');
      pendingResponse.data.forEach((apt, index) => {
        console.log(`  ${index + 1}. ${apt.patientName} - ${apt.service} - ${apt.appointmentDate} ${apt.timeSlot}`);
        console.log(`     ID: ${apt.id}, Status: ${apt.status}`);
      });
    } else {
      console.log('❌ No pending appointments found on online server');
    }
    
    // Step 4: Test creating a new appointment
    console.log('\n📝 Step 4: Testing appointment creation on online server...');
    
    // Login as a patient
    const patientLoginResponse = await axios.post(`${onlineUrl}/api/auth/login`, {
      email: 'jane.smith@test.com',
      password: 'password123'
    });
    
    const patientToken = patientLoginResponse.data.token;
    console.log('✅ Patient login successful');
    
    // Create a new appointment
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 2);
    const appointmentDate = tomorrow.toISOString().split('T')[0];
    
    const bookingResponse = await axios.post(`${onlineUrl}/api/appointments`, {
      service: 'Dental Checkup',
      appointmentDate: appointmentDate,
      timeSlot: '10:00 AM',
      notes: 'Test appointment from online server'
    }, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ New appointment created on online server:', bookingResponse.data.appointment.id);
    
    // Step 5: Check pending appointments again
    console.log('\n📝 Step 5: Checking pending appointments after new booking...');
    const newPendingResponse = await axios.get(`${onlineUrl}/api/admin/appointments/pending`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Updated pending appointments on online server:');
    console.log('📊 Total pending appointments:', newPendingResponse.data.length);
    
    if (newPendingResponse.data.length > 0) {
      console.log('📋 All pending appointments:');
      newPendingResponse.data.forEach((apt, index) => {
        console.log(`  ${index + 1}. ${apt.patientName} - ${apt.service} - ${apt.appointmentDate} ${apt.timeSlot}`);
        console.log(`     ID: ${apt.id}, Status: ${apt.status}`);
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

testOnlineServer(); 