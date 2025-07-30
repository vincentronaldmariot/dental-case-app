const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testPatientAcceptedAppointments() {
  try {
    console.log('🔍 Testing patient accepted appointments...');
    
    // Step 1: Login as patient
    console.log('\n1️⃣ Logging in as patient...');
    const loginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'rolex@gmail.com',
      password: 'password123'
    });
    
    console.log('✅ Login successful');
    console.log('📊 Login response:', JSON.stringify(loginResponse.data, null, 2));
    
    const patientToken = loginResponse.data.token;
    const patientId = loginResponse.data.patient.id;
    
    console.log(`🔑 Patient ID: ${patientId}`);
    console.log(`🔑 Token: ${patientToken ? 'Present' : 'Missing'}`);
    
    // Step 2: Get patient history
    console.log('\n2️⃣ Fetching patient history...');
    const historyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/history`, {
      headers: {
        'Authorization': `Bearer ${patientToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ History fetch successful');
    console.log('📊 History response status:', historyResponse.status);
    console.log('📊 History response data:', JSON.stringify(historyResponse.data, null, 2));
    
    // Step 3: Check appointments specifically
    if (historyResponse.data.history && historyResponse.data.history.appointments) {
      const appointments = historyResponse.data.history.appointments;
      console.log(`\n3️⃣ Found ${appointments.length} appointments:`);
      
      appointments.forEach((apt, index) => {
        console.log(`   ${index + 1}. ID: ${apt.id}`);
        console.log(`      Status: ${apt.status}`);
        console.log(`      Service: ${apt.service}`);
        console.log(`      Date: ${apt.date}`);
        console.log(`      Time Slot: ${apt.timeSlot}`);
        console.log(`      Created At: ${apt.createdAt}`);
        console.log('');
      });
      
      // Check for approved appointments
      const approvedAppointments = appointments.filter(apt => apt.status === 'approved');
      console.log(`\n4️⃣ Approved appointments: ${approvedAppointments.length}`);
      
      if (approvedAppointments.length > 0) {
        console.log('✅ Found approved appointments!');
        approvedAppointments.forEach((apt, index) => {
          console.log(`   ${index + 1}. ID: ${apt.id} - ${apt.service} - ${apt.date}`);
        });
      } else {
        console.log('❌ No approved appointments found');
        
        // Check what statuses exist
        const statuses = [...new Set(appointments.map(apt => apt.status))];
        console.log(`\n📊 Available statuses: ${statuses.join(', ')}`);
      }
    } else {
      console.log('❌ No appointments found in history response');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

testPatientAcceptedAppointments(); 