const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAdminPatientsTab() {
  try {
    console.log('🔍 Testing admin patients tab functionality...');
    
    // Step 1: Login as admin
    console.log('\n1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    console.log('✅ Admin login successful');
    const adminToken = adminLoginResponse.data.token;
    
    // Step 2: Get all patients
    console.log('\n2️⃣ Fetching all patients...');
    const patientsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Patients fetch successful');
    console.log('📊 Response status:', patientsResponse.status);
    console.log('📊 Response data:', JSON.stringify(patientsResponse.data, null, 2));
    
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
    
    try {
      const appointmentHistoryResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${firstPatient.id}/appointments`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Appointment history fetch successful');
      console.log('📊 Response status:', appointmentHistoryResponse.status);
      console.log('📊 Response data:', JSON.stringify(appointmentHistoryResponse.data, null, 2));
      
      const appointments = appointmentHistoryResponse.data.appointments || appointmentHistoryResponse.data || [];
      console.log(`📊 Found ${appointments.length} appointments for this patient`);
      
      appointments.forEach((apt, index) => {
        console.log(`   ${index + 1}. ID: ${apt.id}`);
        console.log(`      Service: ${apt.service}`);
        console.log(`      Date: ${apt.appointmentDate || apt.date}`);
        console.log(`      Status: ${apt.status}`);
        console.log(`      Time Slot: ${apt.timeSlot}`);
        console.log('');
      });
      
    } catch (error) {
      console.log('❌ Failed to fetch appointment history');
      console.log('📊 Error:', error.response?.status, error.response?.data);
    }
    
    // Step 4: Test patient details
    console.log('\n4️⃣ Testing patient details...');
    try {
      const patientDetailsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${firstPatient.id}`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Patient details fetch successful');
      console.log('📊 Response status:', patientDetailsResponse.status);
      console.log('📊 Response data:', JSON.stringify(patientDetailsResponse.data, null, 2));
      
    } catch (error) {
      console.log('❌ Failed to fetch patient details');
      console.log('📊 Error:', error.response?.status, error.response?.data);
    }
    
    // Step 5: Test patient survey data
    console.log('\n5️⃣ Testing patient survey data...');
    try {
      const surveyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/surveys/${firstPatient.id}`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Survey data fetch successful');
      console.log('📊 Response status:', surveyResponse.status);
      console.log('📊 Response data:', JSON.stringify(surveyResponse.data, null, 2));
      
    } catch (error) {
      console.log('❌ Failed to fetch survey data');
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

testAdminPatientsTab(); 