const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testPatientFallbackAppointments() {
  try {
    console.log('🔍 Testing patient fallback appointments method...');
    
    // Step 1: Login as patient
    console.log('\n1️⃣ Logging in as patient...');
    const loginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'rolex@gmail.com',
      password: 'password123'
    });
    
    console.log('✅ Login successful');
    const patientToken = loginResponse.data.token;
    const patientId = loginResponse.data.patient.id;
    
    console.log(`🔑 Patient ID: ${patientId}`);
    console.log(`🔑 Token: ${patientToken ? 'Present' : 'Missing'}`);
    
    // Step 2: Test approved appointments endpoint with patient token
    console.log('\n2️⃣ Testing approved appointments endpoint with patient token...');
    try {
      const approvedResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/appointments/approved`, {
        headers: {
          'Authorization': `Bearer ${patientToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Approved appointments endpoint accessible with patient token');
      console.log('📊 Response status:', approvedResponse.status);
      
      const approvedAppointments = approvedResponse.data.approvedAppointments || [];
      const patientApproved = approvedAppointments.filter(apt => apt.patientId === patientId);
      
      console.log(`📊 Found ${patientApproved.length} approved appointments for this patient:`);
      patientApproved.forEach((apt, index) => {
        console.log(`   ${index + 1}. ID: ${apt.appointmentId} - ${apt.service} - ${apt.appointmentDate}`);
      });
      
    } catch (error) {
      console.log('❌ Approved appointments endpoint not accessible with patient token');
      console.log('📊 Error:', error.response?.status, error.response?.data);
    }
    
    // Step 3: Test pending appointments endpoint with patient token
    console.log('\n3️⃣ Testing pending appointments endpoint with patient token...');
    try {
      const pendingResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/appointments/pending`, {
        headers: {
          'Authorization': `Bearer ${patientToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Pending appointments endpoint accessible with patient token');
      console.log('📊 Response status:', pendingResponse.status);
      
      const pendingAppointments = pendingResponse.data.pendingAppointments || [];
      const patientPending = pendingAppointments.filter(apt => apt.patientId === patientId);
      
      console.log(`📊 Found ${patientPending.length} pending appointments for this patient:`);
      patientPending.forEach((apt, index) => {
        console.log(`   ${index + 1}. ID: ${apt.appointmentId} - ${apt.service} - ${apt.appointmentDate}`);
      });
      
    } catch (error) {
      console.log('❌ Pending appointments endpoint not accessible with patient token');
      console.log('📊 Error:', error.response?.status, error.response?.data);
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

testPatientFallbackAppointments(); 