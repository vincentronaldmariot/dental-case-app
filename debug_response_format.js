const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function debugResponseFormat() {
  try {
    console.log('🔍 Debugging response formats...');
    
    // Login as admin
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
      
      // Test pending appointments endpoint
      console.log('\n📋 Testing pending appointments response format...');
      const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });
      
      console.log('Status:', pendingResponse.status);
      console.log('Response type:', typeof pendingResponse.data);
      console.log('Is Array:', Array.isArray(pendingResponse.data));
      console.log('Response data:', JSON.stringify(pendingResponse.data, null, 2));
      
      // Test all appointments endpoint
      console.log('\n📊 Testing all appointments response format...');
      const allAppointmentsResponse = await axios.get(`${BASE_URL}/api/admin/appointments`, { headers });
      
      console.log('Status:', allAppointmentsResponse.status);
      console.log('Response type:', typeof allAppointmentsResponse.data);
      console.log('Is Array:', Array.isArray(allAppointmentsResponse.data));
      console.log('Response data:', JSON.stringify(allAppointmentsResponse.data, null, 2));
      
    } else {
      console.log('❌ Admin login failed:', loginResponse.status);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
  }
}

debugResponseFormat(); 