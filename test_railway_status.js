const axios = require('axios');

const API_BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testRailwayStatus() {
  try {
    console.log('🔍 Testing Railway Deployment Status...\n');
    console.log('API URL:', API_BASE_URL);

    // Test basic connectivity
    console.log('📡 Testing basic connectivity...');
    try {
      const healthResponse = await axios.get(`${API_BASE_URL}/health`, { timeout: 5000 });
      console.log('✅ Health check successful:', healthResponse.status);
    } catch (healthError) {
      console.log('❌ Health check failed:', healthError.message);
    }

    // Test API root
    console.log('\n📡 Testing API root...');
    try {
      const rootResponse = await axios.get(`${API_BASE_URL}/`, { timeout: 5000 });
      console.log('✅ API root accessible:', rootResponse.status);
    } catch (rootError) {
      console.log('❌ API root failed:', rootError.message);
    }

    // Test registration endpoint
    console.log('\n📡 Testing registration endpoint...');
    try {
      const registerResponse = await axios.post(`${API_BASE_URL}/api/auth/register`, {
        firstName: 'Test',
        lastName: 'User',
        email: 'test@example.com',
        password: 'testpass123',
        phone: '09123456789',
        dateOfBirth: '1990-01-01',
        classification: 'Military'
      }, { timeout: 10000 });
      
      console.log('✅ Registration endpoint working:', registerResponse.status);
    } catch (registerError) {
      console.log('❌ Registration endpoint failed:', registerError.message);
      if (registerError.response) {
        console.log('  Status:', registerError.response.status);
        console.log('  Data:', registerError.response.data);
      }
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run the test
testRailwayStatus(); 