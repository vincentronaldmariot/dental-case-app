const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testRailwayDebug() {
  try {
    console.log('🔍 Debugging Railway deployment...\n');

    // Login as admin
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const token = loginResponse.data.token;
    const headers = { Authorization: `Bearer ${token}` };

    console.log('✅ Admin login successful');

    // Get pending appointments
    console.log('📋 Fetching pending appointments...');
    const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });

    console.log('📊 Response status:', pendingResponse.status);
    console.log('📊 Response data type:', typeof pendingResponse.data);
    console.log('📊 Response data length:', pendingResponse.data?.length);
    console.log('📊 Full response data:', JSON.stringify(pendingResponse.data, null, 2));

    if (pendingResponse.data && pendingResponse.data.length > 0) {
      const appointment = pendingResponse.data[0];
      console.log('\n📋 First appointment:');
      console.log(JSON.stringify(appointment, null, 2));
      
      // Check field names
      console.log('\n🔍 Checking field names:');
      console.log('id:', appointment.id);
      console.log('patientId:', appointment.patientId);
      console.log('patientName:', appointment.patientName);
      console.log('service:', appointment.service);
      console.log('appointmentDate:', appointment.appointmentDate);
      console.log('timeSlot:', appointment.timeSlot);
      console.log('status:', appointment.status);
    }

  } catch (error) {
    console.error('❌ Railway debug failed:', error.response?.data || error.message);
    console.error('❌ Error details:', error.response?.status, error.response?.statusText);
  }
}

testRailwayDebug(); 