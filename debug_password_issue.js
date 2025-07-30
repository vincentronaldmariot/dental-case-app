const axios = require('axios');
const bcrypt = require('bcryptjs');

const API_BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function debugPasswordIssue() {
  try {
    console.log('🔍 Debugging Password Issue...\n');

    // Test credentials
    const testPatient = {
      firstName: 'Debug',
      lastName: 'Patient',
      email: 'debugpatient@example.com',
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
    const registerResponse = await axios.post(`${API_BASE_URL}/api/auth/register`, testPatient);
    
    if (registerResponse.status === 201) {
      console.log('✅ Registration successful!');
      console.log('Patient ID:', registerResponse.data.patient.id);
      console.log('Registration Token:', registerResponse.data.token ? 'Yes' : 'No');
      
      // Store the patient ID for debugging
      const patientId = registerResponse.data.patient.id;
      
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
        } else {
          console.log('❌ Login failed:', loginResponse.status, loginResponse.data);
        }
      } catch (loginError) {
        console.log('❌ Login error:', loginError.response?.status, loginError.response?.data);
      }
      
      // Step 3: Test password hashing manually
      console.log('\n🔐 Step 3: Testing password hashing manually...');
      const testPassword = testPatient.password;
      const hashedPassword = await bcrypt.hash(testPassword, 12);
      console.log('Original password:', testPassword);
      console.log('Hashed password:', hashedPassword);
      
      // Test bcrypt comparison
      const isValid = await bcrypt.compare(testPassword, hashedPassword);
      console.log('Bcrypt comparison result:', isValid);
      
      // Step 4: Try to get patient profile to see stored data
      console.log('\n🔍 Step 4: Checking patient profile...');
      try {
        const profileResponse = await axios.get(`${API_BASE_URL}/api/patients/profile`, {
          headers: {
            'Authorization': `Bearer ${registerResponse.data.token}`
          }
        });
        
        if (profileResponse.status === 200) {
          console.log('✅ Profile retrieved successfully');
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
    console.error('❌ Debug failed:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
  }
}

// Run the debug
debugPasswordIssue();