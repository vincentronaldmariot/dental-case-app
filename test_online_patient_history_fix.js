const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testPatientHistory() {
  try {
    console.log('🔍 Testing online server patient history endpoint...');
    
    // First, login as a patient to get a token
    const loginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'rolex@gmail.com',
      password: 'password123'
    });
    
    console.log('📊 Login response status:', loginResponse.status);
    console.log('📊 Login response data:', JSON.stringify(loginResponse.data, null, 2));
    
    if (loginResponse.status !== 200) {
      console.log('❌ Patient login failed:', loginResponse.status);
      return;
    }
    
    const patientToken = loginResponse.data.token;
    const patientId = loginResponse.data.patient.id;
    
    console.log('✅ Patient login successful');
    console.log('👤 Patient ID:', patientId);
    
    // Test the patient history endpoint
    const historyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/history`, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('📊 Patient history response status:', historyResponse.status);
    console.log('📊 Patient history data:', JSON.stringify(historyResponse.data, null, 2));
    
  } catch (error) {
    console.log('❌ Error testing patient history:', error.response?.status, error.response?.data);
    console.log('❌ Full error:', error.message);
    if (error.response) {
      console.log('❌ Response status:', error.response.status);
      console.log('❌ Response data:', error.response.data);
    }
  }
}

testPatientHistory(); 