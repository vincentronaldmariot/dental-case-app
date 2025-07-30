const axios = require('axios');

async function testPendingEndpoint() {
  try {
    console.log('🧪 Testing the specific pending appointments endpoint...');
    
    // Step 1: Login as admin
    console.log('📝 Step 1: Logging in as admin...');
    const adminLoginResponse = await axios.post('http://localhost:3000/api/auth/admin/login', {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');
    
    // Step 2: Test the endpoint that Flutter app calls
    console.log('\n📝 Step 2: Testing /admin/appointments/pending endpoint...');
    const pendingResponse = await axios.get('http://localhost:3000/api/admin/appointments/pending', {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Pending appointments response:');
    console.log('📊 Status:', pendingResponse.status);
    console.log('📊 Total pending appointments:', pendingResponse.data.length);
    
    if (pendingResponse.data.length > 0) {
      console.log('📋 Pending appointments:');
      pendingResponse.data.forEach((apt, index) => {
        console.log(`  ${index + 1}. ${apt.patientName} - ${apt.service} - ${apt.appointmentDate} ${apt.timeSlot}`);
        console.log(`     ID: ${apt.id}, Status: ${apt.status}`);
      });
    } else {
      console.log('❌ No pending appointments found');
    }
    
    // Step 3: Also test the other endpoint for comparison
    console.log('\n📝 Step 3: Testing /admin/pending-appointments endpoint for comparison...');
    const pendingAltResponse = await axios.get('http://localhost:3000/api/admin/pending-appointments', {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Alternative pending appointments response:');
    console.log('📊 Status:', pendingAltResponse.status);
    console.log('📊 Total pending appointments:', pendingAltResponse.data.length);
    
    if (pendingAltResponse.data.length > 0) {
      console.log('📋 Pending appointments (alternative endpoint):');
      pendingAltResponse.data.forEach((apt, index) => {
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

testPendingEndpoint(); 