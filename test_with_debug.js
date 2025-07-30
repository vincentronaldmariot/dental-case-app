const axios = require('axios');

const API_BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testWithDebug() {
  try {
    console.log('🧪 Testing with Debug Output...\n');

    // Test credentials
    const testPatient = {
      firstName: 'Debug',
      lastName: 'Test',
      email: 'debugtest@example.com',
      password: 'debugpass123',
      phone: '09123456789',
      dateOfBirth: '1990-01-01',
      address: 'Debug Address',
      emergencyContact: 'Emergency Contact',
      emergencyPhone: '09876543210',
      medicalHistory: '',
      allergies: '',
      serialNumber: 'DEBUG123',
      unitAssignment: 'Debug Unit',
      classification: 'Military',
      otherClassification: ''
    };

    // Step 1: Register the patient
    console.log('📝 Step 1: Registering patient...');
    console.log('Registration payload:', JSON.stringify(testPatient, null, 2));
    
    const registerResponse = await axios.post(`${API_BASE_URL}/api/auth/register`, testPatient);
    
    if (registerResponse.status === 201) {
      console.log('✅ Registration successful!');
      console.log('Patient ID:', registerResponse.data.patient.id);
      console.log('Registration response:', JSON.stringify(registerResponse.data, null, 2));
      
      // Step 2: Try to login immediately with the same credentials
      console.log('\n🔐 Step 2: Testing login with registered credentials...');
      const loginPayload = {
        email: testPatient.email,
        password: testPatient.password
      };
      console.log('Login payload:', JSON.stringify(loginPayload, null, 2));
      
      try {
        const loginResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, loginPayload);
        
        if (loginResponse.status === 200) {
          console.log('✅ Login successful!');
          console.log('Login response:', JSON.stringify(loginResponse.data, null, 2));
        } else {
          console.log('❌ Login failed:', loginResponse.status, loginResponse.data);
        }
      } catch (loginError) {
        console.log('❌ Login error:', loginError.response?.status, loginError.response?.data);
      }
      
    } else {
      console.log('❌ Registration failed:', registerResponse.status, registerResponse.data);
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
testWithDebug();