const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testAppointmentDetailsFix() {
  try {
    console.log('🔍 Testing appointment details fix...\n');

    // Login as admin
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      email: 'admin@dentalcase.com',
      password: 'admin123'
    });

    const token = loginResponse.data.token;
    const headers = { Authorization: `Bearer ${token}` };

    console.log('✅ Admin login successful');

    // Get pending appointments
    const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });
    
    if (pendingResponse.data.length === 0) {
      console.log('⚠️  No pending appointments found');
      return;
    }

    const appointment = pendingResponse.data[0];
    console.log('📋 Sample appointment data structure:');
    console.log(JSON.stringify(appointment, null, 2));

    // Check if all required fields are present
    const requiredFields = ['id', 'service', 'appointmentDate', 'timeSlot', 'status', 'patientName', 'patientEmail', 'patientPhone'];
    const missingFields = requiredFields.filter(field => !appointment.hasOwnProperty(field));

    if (missingFields.length > 0) {
      console.log('❌ Missing fields:', missingFields);
    } else {
      console.log('✅ All required fields present');
    }

    // Check for null values that could cause issues
    const nullFields = Object.entries(appointment)
      .filter(([key, value]) => value === null)
      .map(([key]) => key);

    if (nullFields.length > 0) {
      console.log('⚠️  Fields with null values:', nullFields);
    } else {
      console.log('✅ No null values found');
    }

    console.log('\n🎯 Appointment details dialog should now work correctly!');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testAppointmentDetailsFix(); 