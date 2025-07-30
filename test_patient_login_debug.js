const axios = require('axios');

const API_BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testPatientRegistrationAndLogin() {
  try {
    console.log('🧪 Testing Patient Registration and Login...\n');

    // Test credentials
    const testPatient = {
      firstName: 'Test',
      lastName: 'Patient',
      email: 'testpatient@example.com',
      password: 'testpass123',
      phone: '09123456789',
      dateOfBirth: '1990-01-01',
      address: 'Test Address',
      emergencyContact: 'Emergency Contact',
      emergencyPhone: '09876543210',
      medicalHistory: '',
      allergies: '',
      serialNumber: 'TEST123',
      unitAssignment: 'Test Unit',
      classification: 'Military',
      otherClassification: ''
    };

    // Step 1: Register the patient
    console.log('📝 Step 1: Registering patient...');
    const registerResponse = await axios.post(`${API_BASE_URL}/api/auth/register`, testPatient);
    
    if (registerResponse.status === 201) {
      console.log('✅ Registration successful!');
      console.log('Patient ID:', registerResponse.data.patient.id);
      console.log('Token received:', registerResponse.data.token ? 'Yes' : 'No');
    } else {
      console.log('❌ Registration failed:', registerResponse.status, registerResponse.data);
      return;
    }

    console.log('\n🔐 Step 2: Testing login with registered credentials...');
    
    // Step 2: Try to login with the same credentials
    const loginResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, {
      email: testPatient.email,
      password: testPatient.password
    });

    if (loginResponse.status === 200) {
      console.log('✅ Login successful!');
      console.log('Login Token:', loginResponse.data.token ? 'Yes' : 'No');
      console.log('Patient Data:', loginResponse.data.patient);
    } else {
      console.log('❌ Login failed:', loginResponse.status, loginResponse.data);
    }

    // Step 3: Test with wrong password
    console.log('\n🔐 Step 3: Testing login with wrong password...');
    try {
      const wrongPasswordResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, {
        email: testPatient.email,
        password: 'wrongpassword'
      });
      console.log('❌ Wrong password login should have failed but succeeded:', wrongPasswordResponse.status);
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ Wrong password correctly rejected (401)');
      } else {
        console.log('❌ Unexpected error with wrong password:', error.response?.status, error.response?.data);
      }
    }

    // Step 4: Test with non-existent email
    console.log('\n🔐 Step 4: Testing login with non-existent email...');
    try {
      const nonExistentResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, {
        email: 'nonexistent@example.com',
        password: 'anypassword'
      });
      console.log('❌ Non-existent email login should have failed but succeeded:', nonExistentResponse.status);
    } catch (error) {
      if (error.response && error.response.status === 401) {
        console.log('✅ Non-existent email correctly rejected (401)');
      } else {
        console.log('❌ Unexpected error with non-existent email:', error.response?.status, error.response?.data);
      }
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
testPatientRegistrationAndLogin();