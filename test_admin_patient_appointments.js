const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAdminPatientAppointments() {
  try {
    console.log('🔍 Testing admin access to patient appointments...');
    
    // Step 1: Login as admin
    console.log('\n1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    console.log('✅ Admin login successful');
    const adminToken = adminLoginResponse.data.token;
    
    // Step 2: Get all appointments as admin
    console.log('\n2️⃣ Fetching all appointments as admin...');
    const appointmentsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/appointments/pending`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Appointments fetch successful');
    console.log('📊 Response status:', appointmentsResponse.status);
    
    const appointments = appointmentsResponse.data.pendingAppointments || appointmentsResponse.data || [];
    console.log(`📊 Found ${appointments.length} appointments total`);
    
    // Step 3: Filter for our specific patient
    const patientId = '678d93be-c534-4ea3-835b-441591592a4b';
    const patientAppointments = appointments.filter(apt => apt.patientId === patientId);
    
    console.log(`\n3️⃣ Found ${patientAppointments.length} appointments for patient ${patientId}:`);
    
    patientAppointments.forEach((apt, index) => {
      console.log(`   ${index + 1}. ID: ${apt.id}`);
      console.log(`      Status: ${apt.status}`);
      console.log(`      Service: ${apt.service}`);
      console.log(`      Date: ${apt.appointmentDate || apt.date}`);
      console.log(`      Time Slot: ${apt.timeSlot}`);
      console.log(`      Created At: ${apt.createdAt}`);
      console.log('');
    });
    
    // Step 4: Check approved appointments specifically
    const approvedAppointments = patientAppointments.filter(apt => apt.status === 'approved');
    console.log(`\n4️⃣ Approved appointments for patient: ${approvedAppointments.length}`);
    
    if (approvedAppointments.length > 0) {
      console.log('✅ Found approved appointments!');
      approvedAppointments.forEach((apt, index) => {
        console.log(`   ${index + 1}. ID: ${apt.id} - ${apt.service} - ${apt.appointmentDate || apt.date}`);
      });
    } else {
      console.log('❌ No approved appointments found for this patient');
      
      // Check what statuses exist for this patient
      const statuses = [...new Set(patientAppointments.map(apt => apt.status))];
      console.log(`\n📊 Available statuses for this patient: ${statuses.join(', ')}`);
    }
    
    // Step 5: Check all appointments by status
    console.log('\n5️⃣ All appointments by status:');
    const statusCounts = {};
    appointments.forEach(apt => {
      statusCounts[apt.status] = (statusCounts[apt.status] || 0) + 1;
    });
    
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`   ${status}: ${count}`);
    });
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

testAdminPatientAppointments(); 