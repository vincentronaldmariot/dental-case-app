const axios = require('axios');

const API_BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testFixedEndpoints() {
  try {
    console.log('🧪 Testing Fixed API Endpoints...\n');

    // Test credentials
    const testPatient = {
      firstName: 'Fixed',
      lastName: 'Patient',
      email: 'fixedpatient@example.com',
      password: 'fixedpass123',
      phone: '09123456789',
      dateOfBirth: '1990-01-01',
      address: 'Fixed Address',
      emergencyContact: 'Emergency Contact',
      emergencyPhone: '09876543210',
      medicalHistory: '',
      allergies: '',
      serialNumber: 'FIXED123',
      unitAssignment: 'Fixed Unit',
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
      
      // Step 2: Try to login immediately with the same credentials
      console.log('\n🔐 Step 2: Testing login with registered credentials...');
      try {
        const loginResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, {
          email: testPatient.email,
          password: testPatient.password
        });
        
        if (loginResponse.status === 200) {
          console.log('✅ Login successful!');
          console.log('Login Token:', loginResponse.data.token ? 'Yes' : 'No');
          console.log('Patient Data:', loginResponse.data.patient);
          
          // Step 3: Test with the token
          console.log('\n🔐 Step 3: Testing token-based requests...');
          try {
            const profileResponse = await axios.get(`${API_BASE_URL}/api/patients/profile`, {
              headers: {
                'Authorization': `Bearer ${loginResponse.data.token}`
              }
            });
            
            if (profileResponse.status === 200) {
              console.log('✅ Profile retrieval successful!');
              console.log('Profile data available:', profileResponse.data ? 'Yes' : 'No');
            } else {
              console.log('❌ Profile retrieval failed:', profileResponse.status, profileResponse.data);
            }
          } catch (profileError) {
            console.log('❌ Profile error:', profileError.response?.status, profileError.response?.data);
          }
          
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
testFixedEndpoints();