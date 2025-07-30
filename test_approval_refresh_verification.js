const axios = require('axios');

const API_BASE_URL = 'https://afp-dental-app-production.up.railway.app/api'; // Railway deployment

async function testApprovalRefreshFlow() {
  console.log('🧪 Testing Approval/Rejection Refresh Flow...\n');

  try {
    // Step 1: Admin Login
    console.log('1️⃣ Admin Login...');
    const loginResponse = await axios.post(`${API_BASE_URL}/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    if (loginResponse.status !== 200) {
      throw new Error('Admin login failed');
    }

    const adminToken = loginResponse.data.token;
    console.log('✅ Admin login successful\n');

    // Step 2: Check current pending appointments
    console.log('2️⃣ Checking current pending appointments...');
    const pendingResponse = await axios.get(`${API_BASE_URL}/admin/appointments/pending`, {
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });

    const pendingAppointments = pendingResponse.data.pendingAppointments || [];
    console.log(`📋 Found ${pendingAppointments.length} pending appointments`);

    if (pendingAppointments.length === 0) {
      console.log('⚠️  No pending appointments to test with');
      console.log('💡 You may need to create a test appointment first');
      return;
    }

    const testAppointment = pendingAppointments[0];
    console.log(`🎯 Testing with appointment ID: ${testAppointment.id}`);
    console.log(`👤 Patient: ${testAppointment.patientName}`);
    console.log(`🦷 Service: ${testAppointment.service}\n`);

    // Step 3: Test approval
    console.log('3️⃣ Testing appointment approval...');
    const approveResponse = await axios.post(
      `${API_BASE_URL}/admin/appointments/${testAppointment.id}/approve`,
      { notes: 'Test approval notes' },
      { headers: { 'Authorization': `Bearer ${adminToken}` } }
    );

    if (approveResponse.status === 200) {
      console.log('✅ Appointment approved successfully');
    } else {
      throw new Error(`Approval failed: ${approveResponse.status}`);
    }

    // Step 4: Verify appointment moved from pending
    console.log('\n4️⃣ Verifying appointment moved from pending...');
    await new Promise(resolve => setTimeout(resolve, 1000)); // Wait 1 second

    const pendingAfterResponse = await axios.get(`${API_BASE_URL}/admin/appointments/pending`, {
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });

    const pendingAfter = pendingAfterResponse.data.pendingAppointments || [];
    const stillPending = pendingAfter.find(apt => apt.id === testAppointment.id);
    
    if (stillPending) {
      console.log('❌ FAILED: Appointment still appears in pending list');
      console.log('🔍 This indicates a UI refresh issue in the Flutter app');
    } else {
      console.log('✅ SUCCESS: Appointment no longer in pending list');
    }

    // Step 5: Check approved appointments
    console.log('\n5️⃣ Checking approved appointments...');
    const approvedResponse = await axios.get(`${API_BASE_URL}/admin/appointments/approved`, {
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });

    const approvedAppointments = approvedResponse.data.approvedAppointments || [];
    const foundInApproved = approvedAppointments.find(apt => apt.id === testAppointment.id);
    
    if (foundInApproved) {
      console.log('✅ SUCCESS: Appointment found in approved list');
    } else {
      console.log('❌ FAILED: Appointment not found in approved list');
    }

    console.log('\n🎉 Test completed successfully!');
    console.log('💡 If the Flutter app UI is not updating properly, the issue is likely in the frontend refresh logic.');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

// Run the test
testApprovalRefreshFlow(); 