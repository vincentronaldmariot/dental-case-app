const axios = require('axios');

const API_BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testDirectDbCheck() {
  try {
    console.log('🔍 Direct Database Check...\n');

    // Test credentials
    const testPatient = {
      firstName: 'Direct',
      lastName: 'Check',
      email: 'directcheck@example.com',
      password: 'directpass123',
      phone: '09123456789',
      dateOfBirth: '1990-01-01',
      address: 'Direct Check Address',
      emergencyContact: 'Emergency Contact',
      emergencyPhone: '09876543210',
      medicalHistory: '',
      allergies: '',
      serialNumber: 'DIRECT123',
      unitAssignment: 'Direct Unit',
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
      console.log('Full response:', JSON.stringify(registerResponse.data, null, 2));
      
      // Step 2: Try to get patient profile using the registration token
      console.log('\n🔐 Step 2: Testing profile retrieval with registration token...');
      try {
        const profileResponse = await axios.get(`${API_BASE_URL}/api/patients/profile`, {
          headers: {
            'Authorization': `Bearer ${registerResponse.data.token}`
          }
        });
        
        if (profileResponse.status === 200) {
          console.log('✅ Profile retrieval successful!');
          console.log('Profile data:', JSON.stringify(profileResponse.data, null, 2));
        } else {
          console.log('❌ Profile retrieval failed:', profileResponse.status, profileResponse.data);
        }
      } catch (profileError) {
        console.log('❌ Profile error:', profileError.response?.status, profileError.response?.data);
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
testDirectDbCheck(); 