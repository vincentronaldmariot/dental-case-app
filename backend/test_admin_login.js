const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAdminLogin() {
  try {
    console.log('🔐 Testing admin login...');
    console.log('URL:', `${BASE_URL}/api/auth/admin/login`);
    
    const response = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    }, {
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Admin login successful');
    console.log('Response:', response.data);
    return response.data.token;
    
  } catch (error) {
    console.log('❌ Admin login failed');
    console.log('Error status:', error.response?.status);
    console.log('Error data:', error.response?.data);
    console.log('Error message:', error.message);
    throw error;
  }
}

// Run the test
testAdminLogin()
  .then(token => {
    console.log('🎉 Test completed successfully');
  })
  .catch(error => {
    console.log('💥 Test failed');
    process.exit(1);
  });