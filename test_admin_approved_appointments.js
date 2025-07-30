const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAdminApprovedAppointments() {
  try {
    console.log('🔍 Testing admin approved appointments...');
    
    // Step 1: Login as admin
    console.log('\n1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    console.log('✅ Admin login successful');
    const adminToken = adminLoginResponse.data.token;
    
    // Step 2: Get approved appointments as admin
    console.log('\n2️⃣ Fetching approved appointments as admin...');
    const approvedResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/appointments/approved`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Approved appointments fetch successful');
    console.log('📊 Response status:', approvedResponse.status);
    console.log('📊 Response data:', JSON.stringify(approvedResponse.data, null, 2));
    
    const approvedAppointments = approvedResponse.data.approvedAppointments || approvedResponse.data || [];
    console.log(`📊 Found ${approvedAppointments.length} approved appointments total`);
    
    // Step 3: Filter for our specific patient
    const patientId = '678d93be-c534-4ea3-835b-441591592a4b';
    const patientApprovedAppointments = approvedAppointments.filter(apt => apt.patientId === patientId);
    
    console.log(`\n3️⃣ Found ${patientApprovedAppointments.length} approved appointments for patient ${patientId}:`);
    
    patientApprovedAppointments.forEach((apt, index) => {
      console.log(`   ${index + 1}. ID: ${apt.id}`);
      console.log(`      Status: ${apt.status}`);
      console.log(`      Service: ${apt.service}`);
      console.log(`      Date: ${apt.appointmentDate || apt.date}`);
      console.log(`      Time Slot: ${apt.timeSlot}`);
      console.log(`      Created At: ${apt.createdAt}`);
      console.log('');
    });
    
    // Step 4: Check all approved appointments
    if (approvedAppointments.length > 0) {
      console.log('\n4️⃣ All approved appointments:');
      approvedAppointments.forEach((apt, index) => {
        console.log(`   ${index + 1}. Patient: ${apt.patientId} - ${apt.service} - ${apt.appointmentDate || apt.date}`);
      });
    } else {
      console.log('\n4️⃣ No approved appointments found in the system');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

testAdminApprovedAppointments(); 