const axios = require('axios');

const API_BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function checkDeploymentStatus() {
  try {
    console.log('🔍 Checking Deployment Status...\n');

    // Test credentials
    const testPatient = {
      firstName: 'Check',
      lastName: 'Status',
      email: 'checkstatus@example.com',
      password: 'checkpass123',
      phone: '09123456789',
      dateOfBirth: '1990-01-01',
      address: 'Check Status Address',
      emergencyContact: 'Emergency Contact',
      emergencyPhone: '09876543210',
      medicalHistory: '',
      allergies: '',
      serialNumber: 'CHECK123',
      unitAssignment: 'Check Unit',
      classification: 'Military',
      otherClassification: ''
    };

    // Step 1: Register the patient
    console.log('📝 Step 1: Registering test patient...');
    const registerResponse = await axios.post(`${API_BASE_URL}/api/auth/register`, testPatient);
    
    if (registerResponse.status === 201) {
      console.log('✅ Registration successful!');
      console.log('Patient ID:', registerResponse.data.patient.id);
      console.log('Phone field:', registerResponse.data.patient.phone);
      
      // Check if fix is deployed
      if (registerResponse.data.patient.phone.startsWith('$2a$')) {
        console.log('\n❌ FIX NOT DEPLOYED YET');
        console.log('   - Phone field contains password hash');
        console.log('   - Login will fail');
        console.log('   - Wait for Railway deployment');
        console.log('   - Check Railway dashboard');
      } else {
        console.log('\n✅ FIX IS DEPLOYED!');
        console.log('   - Phone field contains actual phone number');
        console.log('   - Login should work');
        console.log('   - Safe to register new patients');
        
        // Test login
        console.log('\n🔐 Testing login...');
        try {
          const loginResponse = await axios.post(`${API_BASE_URL}/api/auth/login`, {
            email: testPatient.email,
            password: testPatient.password
          });
          
          if (loginResponse.status === 200) {
            console.log('✅ Login successful! Fix is working!');
          } else {
            console.log('❌ Login failed:', loginResponse.status);
          }
        } catch (loginError) {
          console.log('❌ Login error:', loginError.response?.status);
        }
      }
      
    } else {
      console.log('❌ Registration failed:', registerResponse.status, registerResponse.data);
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

// Run the check
checkDeploymentStatus(); 