const axios = require('axios');

async function testOnlineAppointmentBooking() {
  try {
    console.log('🧪 Testing online server appointment booking...');
    
    const onlineUrl = 'https://afp-dental-app-production.up.railway.app';
    
    // Step 1: Login as patient
    console.log('📝 Step 1: Patient login...');
    const patientLoginResponse = await axios.post(`${onlineUrl}/api/auth/login`, {
      email: 'john.doe@test.com',
      password: 'password123'
    });
    
    const patientToken = patientLoginResponse.data.token;
    const patientId = patientLoginResponse.data.patient.id;
    console.log('✅ Patient login successful');
    console.log('📊 Patient ID:', patientId);
    console.log('📊 Token:', patientToken.substring(0, 20) + '...');
    
    // Step 2: Test appointment booking
    console.log('\n📝 Step 2: Testing appointment booking...');
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const appointmentDate = tomorrow.toISOString().split('T')[0];
    
    const bookingResponse = await axios.post(`${onlineUrl}/api/appointments`, {
      service: 'Dental Checkup',
      appointmentDate: appointmentDate,
      timeSlot: '9:00 AM',
      notes: 'Test appointment booking'
    }, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Appointment booking response:');
    console.log('📊 Status:', bookingResponse.status);
    console.log('📊 Response data:', JSON.stringify(bookingResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ Test failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
      console.error('Headers:', error.response.headers);
    } else {
      console.error('Error:', error.message);
    }
  }
}

testOnlineAppointmentBooking(); 