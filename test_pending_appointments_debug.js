const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testPendingAppointments() {
  try {
    console.log('🔍 Testing pending appointments endpoint...');
    console.log(`🌐 Using URL: ${BASE_URL}`);
    
    // First, let's test if the server is responding at all
    console.log('\n🌐 Testing server connectivity...');
    try {
      const healthCheck = await axios.get(`${BASE_URL}/health`);
      console.log('✅ Server is responding:', healthCheck.status);
    } catch (healthError) {
      console.log('❌ Server health check failed:', healthError.message);
      return;
    }
    
    // Try to login as admin first
    console.log('\n🔐 Attempting admin login...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    if (loginResponse.status === 200) {
      const token = loginResponse.data.token;
      console.log('✅ Admin login successful');
      
      const headers = {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      };
      
      // Test the pending appointments endpoint with authentication
      console.log('\n📋 Testing pending appointments with auth...');
      const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });
      
      if (pendingResponse.status === 200) {
        const pendingData = pendingResponse.data;
        console.log(`✅ Pending endpoint returned ${pendingData.length} appointments`);
        
        if (pendingData.length > 0) {
          console.log('First pending appointment:', JSON.stringify(pendingData[0], null, 2));
        } else {
          console.log('📭 No pending appointments found');
        }
      }
      
      // Also test all appointments to see what's in the database
      console.log('\n📊 Testing all appointments endpoint...');
      const allAppointmentsResponse = await axios.get(`${BASE_URL}/api/admin/appointments`, { headers });
      
      if (allAppointmentsResponse.status === 200) {
        const allAppointments = allAppointmentsResponse.data;
        console.log(`Total appointments in database: ${allAppointments.length}`);
        
        // Group by status
        const statusCounts = {};
        allAppointments.forEach(apt => {
          const status = apt.status || 'unknown';
          statusCounts[status] = (statusCounts[status] || 0) + 1;
        });
        
        console.log('Appointments by status:', statusCounts);
        
        // Show a few appointments of each status
        Object.keys(statusCounts).forEach(status => {
          const appointmentsOfStatus = allAppointments.filter(apt => apt.status === status);
          console.log(`\n${status.toUpperCase()} appointments (${appointmentsOfStatus.length}):`);
          appointmentsOfStatus.slice(0, 3).forEach((apt, index) => {
            console.log(`  ${index + 1}. ID: ${apt.id}, Patient: ${apt.patientName}, Service: ${apt.service}, Date: ${apt.appointmentDate}`);
          });
        });
      }
      
    } else {
      console.log('❌ Admin login failed:', loginResponse.status);
    }
    
  } catch (error) {
    console.error('❌ Error testing pending appointments:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
  }
}

testPendingAppointments(); 