const axios = require('axios');

async function testFlutterConnection() {
  try {
    console.log('🧪 Testing Flutter app connection to backend...');
    
    // Step 1: Test the exact endpoint that Flutter app calls
    console.log('📝 Step 1: Testing Flutter app endpoint...');
    
    // First login as admin (simulating what Flutter app does)
    const adminLoginResponse = await axios.post('http://localhost:3000/api/auth/admin/login', {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');
    
    // Test the exact endpoint that Flutter app calls
    const pendingResponse = await axios.get('http://localhost:3000/api/admin/appointments/pending', {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Flutter app endpoint response:');
    console.log('📊 Status:', pendingResponse.status);
    console.log('📊 Response type:', typeof pendingResponse.data);
    console.log('📊 Is array:', Array.isArray(pendingResponse.data));
    console.log('📊 Total pending appointments:', pendingResponse.data.length);
    
    if (pendingResponse.data.length > 0) {
      console.log('📋 Pending appointments (Flutter format):');
      pendingResponse.data.forEach((apt, index) => {
        console.log(`  ${index + 1}. ${apt.patientName} - ${apt.service} - ${apt.appointmentDate} ${apt.timeSlot}`);
        console.log(`     ID: ${apt.id}, Status: ${apt.status}`);
        console.log(`     Has survey: ${apt.hasSurveyData}`);
      });
    } else {
      console.log('❌ No pending appointments found');
    }
    
    // Step 2: Test if we can create a new appointment and see it immediately
    console.log('\n📝 Step 2: Testing real-time appointment creation...');
    
    // Login as a patient and create an appointment
    const patientLoginResponse = await axios.post('http://localhost:3000/api/auth/login', {
      email: 'jane.smith@test.com',
      password: 'password123'
    });
    
    const patientToken = patientLoginResponse.data.token;
    const patientId = patientLoginResponse.data.patient.id;
    console.log('✅ Patient login successful');
    
    // Create a new appointment
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 2);
    const appointmentDate = tomorrow.toISOString().split('T')[0];
    
    const bookingResponse = await axios.post('http://localhost:3000/api/appointments', {
      service: 'Dental Checkup',
      appointmentDate: appointmentDate,
      timeSlot: '10:00 AM',
      notes: 'Test appointment from Flutter simulation'
    }, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ New appointment created:', bookingResponse.data.appointment.id);
    
    // Immediately check pending appointments again
    console.log('\n📝 Step 3: Checking pending appointments after new booking...');
    const newPendingResponse = await axios.get('http://localhost:3000/api/admin/appointments/pending', {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Updated pending appointments:');
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

testFlutterConnection(); 