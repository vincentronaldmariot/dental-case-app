const axios = require('axios');

const API_BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testSimpleLogin() {
  try {
    console.log('🧪 Testing Simple Login...\n');

    // Try to login with a previously registered patient
    const testCredentials = {
      email: 'temporaryfix@example.com',
      password: 'temppass123'
    };

    console.log('🔐 Testing login with existing patient...');
    console.log('Email:', testCredentials.email);
    
    try {
      const loginResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, testCredentials);
      
      if (loginResponse.status === 200) {
        console.log('✅ Login successful!');
        console.log('Login Token:', loginResponse.data.token ? 'Yes' : 'No');
        console.log('Patient Data:', loginResponse.data.patient);
        
        // Test with the token
        console.log('\n🔐 Testing token-based requests...');
        try {
          const profileResponse = await axios.get(`${API_BASE_URL}/api/patients/profile`, {
            headers: {
              'Authorization': `Bearer ${loginResponse.data.token}`
            }
          });
          
          if (profileResponse.status === 200) {
            console.log('✅ Profile retrieval successful!');
            console.log('Profile data available:', profileResponse.data ? 'Yes' : 'No');
          } else {
            console.log('❌ Profile retrieval failed:', profileResponse.status, profileResponse.data);
          }
        } catch (profileError) {
          console.log('❌ Profile error:', profileError.response?.status, profileError.response?.data);
        }
        
      } else {
        console.log('❌ Login failed:', loginResponse.status, loginResponse.data);
      }
    } catch (loginError) {
      console.log('❌ Login error:', loginError.response?.status, loginError.response?.data);
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
  }
}

// Run the test
testSimpleLogin(); 