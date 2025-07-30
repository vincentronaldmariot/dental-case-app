const axios = require('axios');

const API_BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testCorrectedRegistration() {
  try {
    console.log('🧪 Testing Corrected Registration...\n');

    // Test credentials
    const testPatient = {
      firstName: 'Corrected',
      lastName: 'Registration',
      email: 'correctedreg@example.com',
      password: 'correctedpass123',
      phone: '09123456789',
      dateOfBirth: '1990-01-01',
      address: 'Corrected Address',
      emergencyContact: 'Emergency Contact',
      emergencyPhone: '09876543210',
      medicalHistory: '',
      allergies: '',
      serialNumber: 'CORRECTED123',
      unitAssignment: 'Corrected Unit',
      classification: 'Military',
      otherClassification: ''
    };

    // Step 1: Register the patient
    console.log('📝 Step 1: Registering patient...');
    const registerResponse = await axios.post(`${API_BASE_URL}/api/auth/register`, testPatient);
    
    if (registerResponse.status === 201) {
      console.log('✅ Registration successful!');
      console.log('Patient ID:', registerResponse.data.patient.id);
      console.log('Phone field:', registerResponse.data.patient.phone);
      console.log('Registration response:', JSON.stringify(registerResponse.data, null, 2));
      
      // Step 2: Try to login immediately with the same credentials
      console.log('\n🔐 Step 2: Testing login with registered credentials...');
      try {
        const loginResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, {
          email: testPatient.email,
          password: testPatient.password
        });
        
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
testCorrectedRegistration();