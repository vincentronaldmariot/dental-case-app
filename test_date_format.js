const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testDateFormat() {
  try {
    console.log('🔍 Testing date format from emergency API...');
    
    // Test patient login
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'vincent@gmail.com',
      password: 'password123'
    });
    
    const patientToken = loginResponse.data.token;
    console.log('✅ Patient login successful');
    
    // Create a test emergency record
    const emergencyData = {
      emergencyType: 'severe_toothache',
      priority: 'urgent',
      description: 'Test emergency for date format',
      painLevel: 8,
      symptoms: ['severe pain', 'swelling'],
      location: 'Upper right molar',
      dutyRelated: false,
      unitCommand: null
    };
    
    const createResponse = await axios.post(`${BASE_URL}/api/emergency`, emergencyData, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });
    
    console.log('✅ Emergency record created');
    console.log('Created record:', JSON.stringify(createResponse.data, null, 2));
    
    // Get emergency records
    const emergencyResponse = await axios.get(`${BASE_URL}/api/emergency`, {
      headers: { Authorization: `Bearer ${patientToken}` }
    });
    
    console.log('📋 Emergency records:');
    console.log('Response data:', JSON.stringify(emergencyResponse.data, null, 2));
    
    const records = emergencyResponse.data.emergencyRecords || emergencyResponse.data;
    
    if (Array.isArray(records)) {
      records.forEach((record, index) => {
        console.log(`Record ${index + 1}:`);
        console.log(`  ID: ${record.id}`);
        console.log(`  reportedAt: ${record.reportedAt}`);
        console.log(`  Type: ${typeof record.reportedAt}`);
        console.log('---');
      });
    } else {
      console.log('Records is not an array:', typeof records);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.response?.data || error.message);
    console.error('Full error:', error);
  }
}

testDateFormat(); 