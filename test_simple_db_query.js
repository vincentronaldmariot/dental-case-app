const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testSimpleDbQuery() {
  console.log('🔍 Testing Simple Database Query...\n');

  try {
    // Test 1: Health check
    console.log('📡 Test 1: Health check...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Health check passed:', healthResponse.status);

    // Test 2: Try to get patients (this should work if database is accessible)
    console.log('\n📡 Test 2: Testing patients endpoint...');
    try {
      const patientsResponse = await axios.get(`${BASE_URL}/api/patients`);
      console.log('✅ Patients endpoint:', patientsResponse.status);
      console.log('📊 Patients count:', patientsResponse.data.patients?.length || 0);
    } catch (error) {
      console.log('❌ Patients endpoint failed:', error.response?.status, error.response?.data);
    }

    // Test 3: Try to get surveys
    console.log('\n📡 Test 3: Testing surveys endpoint...');
    try {
      const surveysResponse = await axios.get(`${BASE_URL}/api/surveys`);
      console.log('✅ Surveys endpoint:', surveysResponse.status);
      console.log('📊 Surveys count:', surveysResponse.data.surveys?.length || 0);
    } catch (error) {
      console.log('❌ Surveys endpoint failed:', error.response?.status, error.response?.data);
    }

    // Test 4: Try to get appointments
    console.log('\n📡 Test 4: Testing appointments endpoint...');
    try {
      const appointmentsResponse = await axios.get(`${BASE_URL}/api/appointments`);
      console.log('✅ Appointments endpoint:', appointmentsResponse.status);
      console.log('📊 Appointments count:', appointmentsResponse.data.appointments?.length || 0);
    } catch (error) {
      console.log('❌ Appointments endpoint failed:', error.response?.status, error.response?.data);
    }

    console.log('\n📋 Analysis:');
    console.log('- If all endpoints work, the database connection is fine');
    console.log('- If some endpoints work but admin doesn\'t, it\'s an admin-specific issue');
    console.log('- If all endpoints fail, it\'s a general database connection issue');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testSimpleDbQuery(); 