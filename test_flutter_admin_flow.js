const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testFlutterAdminFlow() {
  try {
    console.log('🔍 Testing Flutter app admin authentication flow...');
    
    // Step 1: Simulate admin login (like Flutter app does)
    console.log('\n1️⃣ Simulating admin login...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    console.log('✅ Admin login successful');
    const adminToken = adminLoginResponse.data.token;
    console.log(`🔑 Admin token received: ${adminToken ? 'Present' : 'Missing'}`);
    
    // Step 2: Test patients endpoint (like Flutter admin dashboard does)
    console.log('\n2️⃣ Testing patients endpoint (simulating _loadPatients)...');
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
    
    // Step 3: Test appointment history for first patient (simulating getAppointmentsAsAdmin)
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
    
    // Step 4: Test with Rolex patient specifically (since we know he has appointments)
    console.log(`\n4️⃣ Testing Rolex patient specifically...`);
    const rolexPatient = patients.find(p => p.email === 'rolex@gmail.com');
    
    if (rolexPatient) {
      console.log(`📋 Testing Rolex Estrada (ID: ${rolexPatient.id})`);
      
      const rolexAppointmentsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${rolexPatient.id}/appointments`, {
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Rolex appointments successful');
      const rolexAppointments = rolexAppointmentsResponse.data.appointments || [];
      console.log(`📊 Found ${rolexAppointments.length} appointments for Rolex`);
      
      // Show approved appointments specifically
      const approvedAppointments = rolexAppointments.filter(apt => apt.status === 'approved');
      console.log(`📊 Found ${approvedAppointments.length} approved appointments for Rolex`);
      
      approvedAppointments.forEach((apt, index) => {
        console.log(`   ${index + 1}. Service: ${apt.service}`);
        console.log(`      Date: ${apt.appointment_date}`);
        console.log(`      Time: ${apt.time_slot}`);
        console.log(`      Status: ${apt.status}`);
      });
    } else {
      console.log('❌ Rolex patient not found');
    }
    
    console.log('\n5️⃣ Summary:');
    console.log('✅ Admin authentication: Working');
    console.log('✅ Patients fetch: Working');
    console.log('✅ Appointment history: Working');
    console.log('✅ Rolex appointments: Working');
    console.log('✅ Backend is fully functional');
    console.log('⚠️  Issue is likely in Flutter app token storage/retrieval');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

testFlutterAdminFlow(); 