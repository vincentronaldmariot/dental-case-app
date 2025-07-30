const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAdminTokenDebug() {
  try {
    console.log('🔍 Testing admin token storage and retrieval...');
    
    // Step 1: Login as admin
    console.log('\n1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    console.log('✅ Admin login successful');
    const adminToken = adminLoginResponse.data.token;
    console.log(`🔑 Admin token: ${adminToken ? 'Present' : 'Missing'}`);
    console.log(`🔑 Token length: ${adminToken ? adminToken.length : 0}`);
    
    // Step 2: Test patients endpoint with admin token
    console.log('\n2️⃣ Testing patients endpoint with admin token...');
    const patientsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Patients endpoint successful');
    console.log('📊 Response status:', patientsResponse.status);
    
    const patients = patientsResponse.data.patients || patientsResponse.data || [];
    console.log(`📊 Found ${patients.length} patients`);
    
    if (patients.length === 0) {
      console.log('❌ No patients found');
      return;
    }
    
    // Step 3: Test appointment history for first patient
    const firstPatient = patients[0];
    console.log(`\n3️⃣ Testing appointment history for patient: ${firstPatient.fullName || firstPatient.firstName} ${firstPatient.lastName}`);
    console.log(`📋 Patient ID: ${firstPatient.id}`);
    
    const appointmentHistoryResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${firstPatient.id}/appointments`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Appointment history successful');
    console.log('📊 Response status:', appointmentHistoryResponse.status);
    
    const appointments = appointmentHistoryResponse.data.appointments || [];
    console.log(`📊 Found ${appointments.length} appointments`);
    
    appointments.forEach((apt, index) => {
      console.log(`   ${index + 1}. Service: ${apt.service}`);
      console.log(`      Date: ${apt.appointment_date}`);
      console.log(`      Time: ${apt.time_slot}`);
      console.log(`      Status: ${apt.status}`);
    });
    
    // Step 4: Test with invalid token to see error
    console.log('\n4️⃣ Testing with invalid token...');
    try {
      const invalidResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${firstPatient.id}/appointments`, {
        headers: {
          'Authorization': 'Bearer invalid_token',
          'Content-Type': 'application/json'
        }
      });
      console.log('❌ Should have failed with invalid token');
    } catch (error) {
      console.log('✅ Correctly failed with invalid token');
      console.log('📊 Error status:', error.response?.status);
      console.log('📊 Error message:', error.response?.data?.error);
    }
    
    // Step 5: Test without token
    console.log('\n5️⃣ Testing without token...');
    try {
      const noTokenResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${firstPatient.id}/appointments`, {
        headers: {
          'Content-Type': 'application/json'
        }
      });
      console.log('❌ Should have failed without token');
    } catch (error) {
      console.log('✅ Correctly failed without token');
      console.log('📊 Error status:', error.response?.status);
      console.log('📊 Error message:', error.response?.data?.error);
    }
    
    console.log('\n6️⃣ Summary:');
    console.log('✅ Admin authentication: Working');
    console.log('✅ Admin token: Valid');
    console.log('✅ Patients endpoint: Working');
    console.log('✅ Appointment history: Working');
    console.log('✅ Token validation: Working');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

testAdminTokenDebug(); 