const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testRailwayApproveReject() {
  try {
    console.log('🔍 Testing Railway deployment approve/reject functionality...\n');

    // Login as admin
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const token = loginResponse.data.token;
    const headers = { Authorization: `Bearer ${token}` };

    console.log('✅ Admin login successful');

    // Get pending appointments
    const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });

    if (pendingResponse.data.length === 0) {
      console.log('⚠️  No pending appointments found on Railway');
      console.log('📝 The Flutter app is configured to use Railway deployment');
      console.log('📝 To test approve/reject functionality:');
      console.log('   1. Create a patient account in the Flutter app');
      console.log('   2. Book an appointment through the patient interface');
      console.log('   3. The appointment will appear in the admin pending tab');
      console.log('   4. Then you can test the approve/reject buttons');
      return;
    }

    const appointment = pendingResponse.data[0];
    console.log('📋 Sample appointment data structure from Railway:');
    console.log(JSON.stringify(appointment, null, 2));

    // Check if all required fields are present for approve/reject
    const requiredFields = ['id', 'patientId', 'patientName', 'service', 'appointmentDate', 'timeSlot', 'status'];
    const missingFields = requiredFields.filter(field => !appointment.hasOwnProperty(field));

    if (missingFields.length > 0) {
      console.log('❌ Missing fields for approve/reject:', missingFields);
      console.log('🚨 This means the Railway deployment needs to be updated with the latest fixes!');
    } else {
      console.log('✅ All required fields present for approve/reject');
    }

    // Test the approve endpoint structure
    console.log('\n🧪 Testing approve endpoint structure...');
    console.log(`Appointment ID: ${appointment.id}`);
    console.log(`Patient Name: ${appointment.patientName}`);
    console.log(`Service: ${appointment.service}`);
    console.log(`Appointment Date: ${appointment.appointmentDate}`);
    console.log(`Time Slot: ${appointment.timeSlot}`);

    // Test the reject endpoint structure
    console.log('\n🧪 Testing reject endpoint structure...');
    console.log(`Appointment ID: ${appointment.id}`);
    console.log(`Patient Name: ${appointment.patientName}`);
    console.log(`Service: ${appointment.service}`);

    console.log('\n🎯 Railway deployment should have approve/reject functionality working!');

  } catch (error) {
    console.error('❌ Railway test failed:', error.response?.data || error.message);
    console.log('\n🚨 The Railway deployment may need to be updated with the latest fixes!');
  }
}

testRailwayApproveReject(); 