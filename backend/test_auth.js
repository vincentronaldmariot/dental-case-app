const axios = require('axios');

const BASE_URL = 'http://localhost:3000/api';

async function testAuth() {
  console.log('🧪 Testing Authentication Endpoints...\n');

  try {
    // Test 1: Health check
    console.log('1. Testing health check...');
    const healthResponse = await axios.get('http://localhost:3000/health');
    console.log('✅ Health check passed:', healthResponse.data);

    // Test 2: Try to register a new user
    console.log('\n2. Testing registration...');
    const testUser = {
      firstName: 'Test',
      lastName: 'User',
      email: 'test@example.com',
      password: 'password123',
      phone: '1234567890',
      dateOfBirth: '1990-01-01',
      address: '123 Test Street',
      emergencyContact: 'Emergency Contact',
      emergencyPhone: '0987654321',
      medicalHistory: 'None',
      allergies: 'None',
      serialNumber: '12345',
      unitAssignment: 'Test Unit',
      classification: 'Military',
      otherClassification: ''
    };

    try {
      const registerResponse = await axios.post(`${BASE_URL}/auth/register`, testUser);
      console.log('✅ Registration successful:', registerResponse.data.message);
    } catch (error) {
      if (error.response?.status === 409) {
        console.log('ℹ️  User already exists, continuing with login test...');
      } else {
        console.log('❌ Registration failed:', error.response?.data || error.message);
      }
    }

    // Test 3: Try to login
    console.log('\n3. Testing login...');
    const loginData = {
      email: 'test@example.com',
      password: 'password123'
    };

    try {
      const loginResponse = await axios.post(`${BASE_URL}/auth/login`, loginData);
      console.log('✅ Login successful:', loginResponse.data.message);
      console.log('Token received:', loginResponse.data.token ? 'Yes' : 'No');
    } catch (error) {
      console.log('❌ Login failed:', error.response?.data || error.message);
    }

    // Test 4: Try to login with wrong password
    console.log('\n4. Testing login with wrong password...');
    const wrongLoginData = {
      email: 'test@example.com',
      password: 'wrongpassword'
    };

    try {
      await axios.post(`${BASE_URL}/auth/login`, wrongLoginData);
      console.log('❌ Login should have failed but succeeded');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log('✅ Login correctly rejected with wrong password');
      } else {
        console.log('❌ Unexpected error:', error.response?.data || error.message);
      }
    }

  } catch (error) {
    console.log('❌ Test failed:', error.message);
  }
}

// Run the test
testAuth(); 