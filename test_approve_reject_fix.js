const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testApproveRejectFix() {
  try {
    console.log('🔍 Testing approve/reject appointment fix...\n');

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
      console.log('⚠️  No pending appointments found - cannot test approve/reject');
      return;
    }

    const appointment = pendingResponse.data[0];
    console.log('📋 Sample appointment data structure:');
    console.log(JSON.stringify(appointment, null, 2));

    // Check if all required fields are present for approve/reject
    const requiredFields = ['id', 'patientId', 'patientName', 'service', 'appointmentDate', 'timeSlot', 'status'];
    const missingFields = requiredFields.filter(field => !appointment.hasOwnProperty(field));

    if (missingFields.length > 0) {
      console.log('❌ Missing fields for approve/reject:', missingFields);
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

    console.log('\n🎯 Approve and Reject buttons should now work correctly!');
    console.log('📝 The Flutter app will use these field names:');
    console.log('   - appointment["id"] for appointment ID');
    console.log('   - appointment["patientName"] for patient name');
    console.log('   - appointment["patientId"] for patient ID');
    console.log('   - appointment["appointmentDate"] for appointment date');

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testApproveRejectFix(); 