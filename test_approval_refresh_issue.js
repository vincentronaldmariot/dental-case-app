const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function testApprovalRefreshIssue() {
  try {
    console.log('🔍 Testing approval refresh issue...\n');

    // Login as admin
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const token = loginResponse.data.token;
    const headers = { Authorization: `Bearer ${token}` };

    console.log('✅ Admin login successful');

    // Get pending appointments
    const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });

    if (pendingResponse.data.length === 0) {
      console.log('⚠️  No pending appointments found');
      console.log('📝 Create a test appointment first to test approval');
      return;
    }

    const appointment = pendingResponse.data[0];
    console.log('📋 Found pending appointment:');
    console.log('ID:', appointment.id);
    console.log('Patient:', appointment.patientName);
    console.log('Service:', appointment.service);
    console.log('Status:', appointment.status);

    // Test approval
    console.log('\n🧪 Testing approval...');
    const approveResponse = await axios.post(
      `${BASE_URL}/api/admin/appointments/${appointment.id}/approve`,
      { notes: 'Test approval' },
      { headers }
    );

    console.log('✅ Approval response:', approveResponse.status);
    console.log('📊 Approval response body:', approveResponse.data);

    // Wait a moment for database update
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Check if appointment is still in pending
    console.log('\n🔍 Checking if appointment is still in pending...');
    const pendingAfterResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });

    const stillPending = pendingAfterResponse.data.find(apt => apt.id === appointment.id);
    if (stillPending) {
      console.log('❌ ISSUE: Appointment still appears in pending list!');
      console.log('📊 Pending appointments after approval:', pendingAfterResponse.data.length);
    } else {
      console.log('✅ SUCCESS: Appointment no longer in pending list');
    }

    // Check if appointment appears in approved
    console.log('\n🔍 Checking if appointment appears in approved...');
    const approvedResponse = await axios.get(`${BASE_URL}/api/admin/appointments/approved`, { headers });

    const inApproved = approvedResponse.data.find(apt => apt.id === appointment.id);
    if (inApproved) {
      console.log('✅ SUCCESS: Appointment found in approved list');
      console.log('📊 Approved appointments count:', approvedResponse.data.length);
    } else {
      console.log('❌ ISSUE: Appointment not found in approved list');
    }

    // Check appointment status directly
    console.log('\n🔍 Checking appointment status directly...');
    const allAppointmentsResponse = await axios.get(`${BASE_URL}/api/admin/appointments`, { headers });
    const appointmentStatus = allAppointmentsResponse.data.find(apt => apt.id === appointment.id);
    
    if (appointmentStatus) {
      console.log('📊 Direct status check:', appointmentStatus.status);
      if (appointmentStatus.status === 'approved') {
        console.log('✅ Database shows appointment as approved');
      } else {
        console.log('❌ Database still shows status as:', appointmentStatus.status);
      }
    } else {
      console.log('❌ Could not find appointment in all appointments');
    }

    console.log('\n📋 SUMMARY:');
    if (stillPending) {
      console.log('🚨 ISSUE: Appointment still appears in pending after approval');
      console.log('🔧 This suggests a UI refresh issue in the Flutter app');
    } else {
      console.log('✅ Approval working correctly');
    }

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
  }
}

testApprovalRefreshIssue(); 