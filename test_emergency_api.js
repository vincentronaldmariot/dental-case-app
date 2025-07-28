const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

// Test patient login to get token
async function testPatientLogin() {
  try {
    console.log('🔐 Testing patient login...');
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: 'vincent@gmail.com',
      password: 'password123'
    });
    
    if (response.data.token) {
      console.log('✅ Patient login successful');
      return response.data.token;
    }
  } catch (error) {
    console.log('❌ Patient login failed:', error.response?.data || error.message);
  }
  return null;
}

// Test emergency record submission
async function testEmergencySubmission(token) {
  try {
    console.log('🚨 Testing emergency record submission...');
    const emergencyData = {
      emergencyType: 'severeToothache',
      priority: 'urgent',
      description: 'Severe pain in upper right molar',
      painLevel: 8,
      symptoms: ['Severe pain', 'Sensitivity to cold', 'Throbbing'],
      location: 'Base quarters',
      dutyRelated: false
    };

    const response = await axios.post(`${BASE_URL}/emergency`, emergencyData, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    if (response.status === 201) {
      console.log('✅ Emergency record submitted successfully');
      console.log('📋 Record ID:', response.data.emergency.id);
      return response.data.emergency.id;
    }
  } catch (error) {
    console.log('❌ Emergency submission failed:', error.response?.data || error.message);
  }
  return null;
}

// Test getting emergency records
async function testGetEmergencyRecords(token) {
  try {
    console.log('📋 Testing get emergency records...');
    const response = await axios.get(`${BASE_URL}/emergency`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    if (response.status === 200) {
      console.log('✅ Emergency records retrieved successfully');
      console.log('📊 Number of records:', response.data.emergencyRecords.length);
      return response.data.emergencyRecords;
    }
  } catch (error) {
    console.log('❌ Get emergency records failed:', error.response?.data || error.message);
  }
  return [];
}

// Test admin login
async function testAdminLogin() {
  try {
    console.log('🔐 Testing admin login...');
    const response = await axios.post(`${BASE_URL}/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    if (response.data.token) {
      console.log('✅ Admin login successful');
      return response.data.token;
    }
  } catch (error) {
    console.log('❌ Admin login failed:', error.response?.data || error.message);
  }
  return null;
}

// Test admin get all emergency records
async function testAdminGetEmergencyRecords(token) {
  try {
    console.log('📋 Testing admin get all emergency records...');
    const response = await axios.get(`${BASE_URL}/admin/emergency`, {
      headers: {
        'Authorization': `Bearer ${token}`
      }
    });

    if (response.status === 200) {
      console.log('✅ Admin emergency records retrieved successfully');
      console.log('📊 Number of records:', response.data.emergencyRecords.length);
      return response.data.emergencyRecords;
    }
  } catch (error) {
    console.log('❌ Admin get emergency records failed:', error.response?.data || error.message);
  }
  return [];
}

// Main test function
async function runTests() {
  console.log('🧪 Starting Emergency API Tests...\n');

  // Test patient flow
  const patientToken = await testPatientLogin();
  if (patientToken) {
    const emergencyId = await testEmergencySubmission(patientToken);
    await testGetEmergencyRecords(patientToken);
  }

  console.log('\n' + '='.repeat(50) + '\n');

  // Test admin flow
  const adminToken = await testAdminLogin();
  if (adminToken) {
    await testAdminGetEmergencyRecords(adminToken);
  }

  console.log('\n🧪 Emergency API Tests completed!');
}

// Run the tests
runTests().catch(console.error); 