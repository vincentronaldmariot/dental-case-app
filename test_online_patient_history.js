const axios = require('axios');

async function testOnlinePatientHistory() {
  try {
    console.log('🧪 Testing online server patient history endpoint...');
    
    const onlineUrl = 'https://afp-dental-app-production.up.railway.app';
    
    // Step 1: Login as patient
    console.log('📝 Step 1: Patient login...');
    const patientLoginResponse = await axios.post(`${onlineUrl}/api/auth/login`, {
      email: 'john.doe@test.com',
      password: 'password123'
    });
    
    const patientToken = patientLoginResponse.data.token;
    const patientId = patientLoginResponse.data.patient.id;
    console.log('✅ Patient login successful');
    console.log('📊 Patient ID:', patientId);
    
    // Step 2: Test patient history endpoint
    console.log('\n📝 Step 2: Testing patient history endpoint...');
    const historyResponse = await axios.get(`${onlineUrl}/api/patients/${patientId}/history`, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Patient history response:');
    console.log('📊 Status:', historyResponse.status);
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

testOnlinePatientHistory(); 