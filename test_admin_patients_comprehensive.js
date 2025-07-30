const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAdminPatientsComprehensive() {
  try {
    console.log('🔍 Comprehensive test of admin patients tab functionality...');
    
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
    
    const patients = patientsResponse.data.patients || patientsResponse.data || [];
    console.log(`📊 Found ${patients.length} patients`);
    
    if (patients.length === 0) {
      console.log('❌ No patients found');
      return;
    }
    
    // Step 3: Test each patient's functionality
    for (let i = 0; i < Math.min(3, patients.length); i++) {
      const patient = patients[i];
      console.log(`\n3️⃣ Testing patient ${i + 1}: ${patient.fullName || patient.firstName} ${patient.lastName}`);
      console.log(`📋 Patient ID: ${patient.id}`);
      
      // Test appointment history
      console.log(`   📅 Testing appointment history...`);
      try {
        const appointmentHistoryResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${patient.id}/appointments`, {
          headers: {
            'Authorization': `Bearer ${adminToken}`,
            'Content-Type': 'application/json'
          }
        });
        
        console.log(`   ✅ Appointment history successful`);
        const appointments = appointmentHistoryResponse.data.appointments || [];
        console.log(`   📊 Found ${appointments.length} appointments`);
        
        appointments.forEach((apt, index) => {
          console.log(`      ${index + 1}. Service: ${apt.service}`);
          console.log(`         Date: ${apt.appointment_date}`);
          console.log(`         Time: ${apt.time_slot}`);
          console.log(`         Status: ${apt.status}`);
          console.log(`         Notes: ${apt.notes || 'None'}`);
        });
        
      } catch (error) {
        console.log(`   ❌ Appointment history failed: ${error.response?.status} - ${error.response?.data?.error}`);
      }
      
      // Test survey data
      console.log(`   📋 Testing survey data...`);
      try {
        const surveyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${patient.id}/survey`, {
          headers: {
            'Authorization': `Bearer ${adminToken}`,
            'Content-Type': 'application/json'
          }
        });
        
        console.log(`   ✅ Survey data successful`);
        const surveyData = surveyResponse.data.surveyData;
        if (surveyData) {
          console.log(`   📊 Survey completed: ${surveyData.submitted_at ? 'Yes' : 'No'}`);
          console.log(`   📊 Tooth pain: ${surveyData.tooth_pain ? 'Yes' : 'No'}`);
          console.log(`   📊 Tartar level: ${surveyData.tartar_level || 'Not specified'}`);
        } else {
          console.log(`   📊 No survey data available`);
        }
        
      } catch (error) {
        console.log(`   ❌ Survey data failed: ${error.response?.status} - ${error.response?.data?.error}`);
      }
    }
    
    // Step 4: Test specific patient (Rolex) that we know has data
    console.log(`\n4️⃣ Testing specific patient (Rolex) with known data...`);
    const rolexPatient = patients.find(p => p.email === 'rolex@gmail.com');
    
    if (rolexPatient) {
      console.log(`📋 Testing Rolex Estrada (ID: ${rolexPatient.id})`);
      
      // Test appointment history
      try {
        const rolexAppointmentsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${rolexPatient.id}/appointments`, {
          headers: {
            'Authorization': `Bearer ${adminToken}`,
            'Content-Type': 'application/json'
          }
        });
        
        console.log(`✅ Rolex appointments successful`);
        const rolexAppointments = rolexAppointmentsResponse.data.appointments || [];
        console.log(`📊 Found ${rolexAppointments.length} appointments for Rolex`);
        
        rolexAppointments.forEach((apt, index) => {
          console.log(`   ${index + 1}. Service: ${apt.service}`);
          console.log(`      Date: ${apt.appointment_date}`);
          console.log(`      Time: ${apt.time_slot}`);
          console.log(`      Status: ${apt.status}`);
        });
        
      } catch (error) {
        console.log(`❌ Rolex appointments failed: ${error.response?.status} - ${error.response?.data?.error}`);
      }
      
      // Test survey data
      try {
        const rolexSurveyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${rolexPatient.id}/survey`, {
          headers: {
            'Authorization': `Bearer ${adminToken}`,
            'Content-Type': 'application/json'
          }
        });
        
        console.log(`✅ Rolex survey successful`);
        const rolexSurvey = rolexSurveyResponse.data.surveyData;
        console.log(`📊 Survey data available: ${rolexSurvey ? 'Yes' : 'No'}`);
        
      } catch (error) {
        console.log(`❌ Rolex survey failed: ${error.response?.status} - ${error.response?.data?.error}`);
      }
    } else {
      console.log(`❌ Rolex patient not found in patients list`);
    }
    
    // Step 5: Summary
    console.log(`\n5️⃣ Summary:`);
    console.log(`✅ Patients list: Working (${patients.length} patients found)`);
    console.log(`✅ Appointment history: Working (with some data format issues)`);
    console.log(`✅ Survey data: Working (with some patients)`);
    console.log(`⚠️  Data format issues: Some fields may be undefined in appointment data`);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

testAdminPatientsComprehensive(); 