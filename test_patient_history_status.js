const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function testPatientHistoryStatus() {
  try {
    console.log('🔍 Testing patient history endpoint status values...');
    
    // Step 1: Login as patient (Rolex)
    console.log('\n1️⃣ Logging in as patient (Rolex)...');
    const patientLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/login`, {
      email: 'rolex@gmail.com',
      password: 'password123'
    });
    
    console.log('✅ Patient login successful');
    const patientToken = patientLoginResponse.data.token;
    const patientId = patientLoginResponse.data.patient.id;
    console.log(`🔑 Patient ID: ${patientId}`);
    
    // Step 2: Test patient history endpoint
    console.log('\n2️⃣ Testing patient history endpoint...');
    try {
      const historyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/patients/${patientId}/history`, {
        headers: {
          'Authorization': `Bearer ${patientToken}`,
          'Content-Type': 'application/json'
        }
      });
      
      console.log('✅ Patient history successful');
      console.log('📊 Response status:', historyResponse.status);
      console.log('📊 Response data:', JSON.stringify(historyResponse.data, null, 2));
      
      if (historyResponse.data.history && historyResponse.data.history.appointments) {
        const appointments = historyResponse.data.history.appointments;
        console.log(`📊 Found ${appointments.length} appointments in history`);
        
        appointments.forEach((apt, index) => {
          console.log(`   ${index + 1}. Service: ${apt.service}`);
          console.log(`      Status: ${apt.status}`);
          console.log(`      Date: ${apt.date}`);
          console.log(`      Time: ${apt.timeSlot}`);
        });
      }
      
    } catch (error) {
      console.log('❌ Patient history failed:');
      console.log('📊 Error status:', error.response?.status);
      console.log('📊 Error data:', error.response?.data);
    }
    
    // Step 3: Test admin endpoint for comparison
    console.log('\n3️⃣ Testing admin endpoint for comparison...');
    
    // Login as admin
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    
    const adminAppointmentsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients/${patientId}/appointments`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Admin appointments successful');
    const adminAppointments = adminAppointmentsResponse.data.appointments || [];
    console.log(`📊 Found ${adminAppointments.length} appointments via admin`);
    
    // Count statuses
    const statusCounts = {};
    adminAppointments.forEach(apt => {
      statusCounts[apt.status] = (statusCounts[apt.status] || 0) + 1;
    });
    
    console.log('📊 Status breakdown from admin endpoint:');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`   - ${status}: ${count}`);
    });
    
    // Show completed appointments specifically
    const completedAppointments = adminAppointments.filter(apt => apt.status === 'completed');
    if (completedAppointments.length > 0) {
      console.log('\n📋 Completed appointments from admin endpoint:');
      completedAppointments.forEach((apt, index) => {
        console.log(`   ${index + 1}. Service: ${apt.service}`);
        console.log(`      Date: ${apt.appointment_date}`);
        console.log(`      Time: ${apt.time_slot}`);
        console.log(`      Status: ${apt.status}`);
      });
    }
    
    console.log('\n4️⃣ Summary:');
    console.log('✅ Patient history endpoint tested');
    console.log('✅ Admin endpoint tested');
    console.log('✅ Status values analyzed');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

testPatientHistoryStatus(); 