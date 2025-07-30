const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAppointmentBooking() {
  try {
    console.log('🔍 Testing online server appointment booking...');
    
    // First, login as a patient to get a token
    const loginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'rolex@gmail.com',
      password: 'password123'
    });
    
    console.log('📊 Login response status:', loginResponse.status);
    console.log('📊 Login response data:', JSON.stringify(loginResponse.data, null, 2));
    
    if (loginResponse.status !== 200) {
      console.log('❌ Patient login failed:', loginResponse.status);
      return;
    }
    
    const patientToken = loginResponse.data.token;
    const patientId = loginResponse.data.patient.id;
    
    console.log('✅ Patient login successful');
    console.log('👤 Patient ID:', patientId);
    console.log('🔑 Token preview:', patientToken.substring(0, 20) + '...');
    
    // Test the appointment booking endpoint
    const bookingData = {
      service: 'Dental Checkup',
      appointmentDate: '2025-02-15',
      timeSlot: '09:00 AM',
      notes: 'Test appointment booking'
    };
    
    console.log('📝 Booking data:', bookingData);
    
    const bookingResponse = await axios.post(`${ONLINE_SERVER_URL}/api/appointments`, bookingData, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Appointment booking successful');
    console.log('📊 Booking response status:', bookingResponse.status);
    console.log('📊 Booking response data:', JSON.stringify(bookingResponse.data, null, 2));
    
  } catch (error) {
    console.log('❌ Error booking appointment:', error.response?.status);
    console.log('❌ Error details:', error.response?.data);
    console.log('❌ Full error:', error.message);
  }
}

testAppointmentBooking(); 