const axios = require('axios');

async function testPatientHistory() {
  try {
    console.log('🧪 Testing patient history endpoint...');
    
    // First, let's try to login as a patient to get a valid token
    // Using a patient that has appointments
    const loginResponse = await axios.post('http://localhost:3000/api/auth/login', {
      email: 'viperson1@gmail.com',
      password: 'password123'
    });
    
    console.log('✅ Login successful');
    const token = loginResponse.data.token;
    const patientId = loginResponse.data.patient.id;
    
    console.log('🔑 Token:', token.substring(0, 20) + '...');
    console.log('👤 Patient ID:', patientId);
    
    // Now test the history endpoint
    const historyResponse = await axios.get(`http://localhost:3000/api/patients/${patientId}/history`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ History request successful');
    console.log('📊 Response data:', JSON.stringify(historyResponse.data, null, 2));
    
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

testPatientHistory(); 