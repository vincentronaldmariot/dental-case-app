const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testRoutes() {
  try {
    console.log('🔍 Testing Available Routes...\n');

    // Test different route patterns
    const routesToTest = [
      '/api/admin/emergency-records',
      '/api/admin/emergency',
      '/api/emergency',
      '/api/admin/patients',
      '/api/admin/appointments',
      '/api/admin/dashboard'
    ];

    for (const route of routesToTest) {
      try {
        console.log(`Testing: ${route}`);
        const response = await axios.get(`${ONLINE_SERVER_URL}${route}`, {
          headers: { 
            'Authorization': 'Bearer test-token',
            'Content-Type': 'application/json'
          },
          timeout: 5000
        });
        console.log(`✅ ${route} - Status: ${response.status}`);
      } catch (error) {
        if (error.response) {
          console.log(`❌ ${route} - Status: ${error.response.status} - ${error.response.data?.error || 'Unknown error'}`);
        } else if (error.code === 'ECONNABORTED') {
          console.log(`⏰ ${route} - Timeout`);
        } else {
          console.log(`❌ ${route} - ${error.message}`);
        }
      }
    }

  } catch (error) {
    console.log('❌ Test failed:', error.message);
  }
}

testRoutes(); 