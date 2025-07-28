const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testEmergencyRoute() {
  try {
    console.log('🔍 Testing emergency route accessibility...');
    
    // Test if the route exists (should return 401 for unauthorized)
    try {
      const response = await axios.get(`${BASE_URL}/api/emergency`);
      console.log('❌ Route should require authentication but returned:', response.status);
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ Route exists and requires authentication (401)');
      } else {
        console.log('❌ Unexpected error:', error.response?.status, error.response?.data);
      }
    }
    
    // Test with invalid token
    try {
      const response = await axios.get(`${BASE_URL}/api/emergency`, {
        headers: { Authorization: 'Bearer invalid_token' }
      });
      console.log('❌ Should not work with invalid token');
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ Correctly rejects invalid token (401)');
      } else {
        console.log('❌ Unexpected error with invalid token:', error.response?.status, error.response?.data);
      }
    }
    
    // Test with valid patient login
    console.log('🔐 Testing with valid patient login...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'vincent@gmail.com',
      password: 'password123'
    });
    
    const patientToken = loginResponse.data.token;
    console.log('✅ Patient login successful');
    
    // Test emergency route with valid token
    const emergencyResponse = await axios.get(`${BASE_URL}/api/emergency`, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });
    
    console.log('✅ Emergency route works with valid token');
    console.log('📊 Response status:', emergencyResponse.status);
    console.log('📄 Response data:', JSON.stringify(emergencyResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    console.error('Full error:', error);
  }
}

testEmergencyRoute(); 