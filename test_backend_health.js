const axios = require('axios');

async function testBackendHealth() {
  try {
    console.log('🏥 Testing backend health...');
    
    // Test health endpoint
    const healthResponse = await axios.get('https://afp-dental-app-production.up.railway.app/health', {
      timeout: 10000
    });
    
    console.log('✅ Backend health check passed');
    console.log('Health response:', healthResponse.data);
    
    // Test surveys endpoint
    const surveysResponse = await axios.get('https://afp-dental-app-production.up.railway.app/api/surveys', {
      headers: {
        'Authorization': 'Bearer kiosk_token'
      },
      timeout: 10000
    });
    
    console.log('✅ Surveys endpoint accessible');
    console.log('Surveys response status:', surveysResponse.status);
    
  } catch (error) {
    console.error('❌ Backend health check failed');
    console.error('Error status:', error.response?.status);
    console.error('Error data:', error.response?.data);
    console.error('Error message:', error.message);
    
    if (error.code === 'ECONNABORTED') {
      console.error('Request timed out');
    }
  }
}

testBackendHealth(); 