const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAdminEndpoints() {
  console.log('🔍 Testing Admin Dashboard Endpoints...\n');

  try {
    // First, get admin token
    console.log('📡 Getting admin token...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    if (loginResponse.status !== 200) {
      console.log('❌ Admin login failed:', loginResponse.status);
      return;
    }

    const token = loginResponse.data.token;
    console.log('✅ Admin login successful\n');

    const headers = {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };

    // Test 1: Dashboard stats
    console.log('📊 Test 1: Dashboard stats...');
    try {
      const dashboardResponse = await axios.get(`${BASE_URL}/api/admin/dashboard`, { headers });
      console.log('✅ Dashboard stats:', dashboardResponse.status);
      console.log('📈 Stats:', JSON.stringify(dashboardResponse.data.stats, null, 2));
    } catch (error) {
      console.log('❌ Dashboard stats failed:', error.response?.status, error.response?.data);
    }

    // Test 2: Approved appointments
    console.log('\n📅 Test 2: Approved appointments...');
    try {
      const approvedResponse = await axios.get(`${BASE_URL}/api/admin/appointments/approved`, { headers });
      console.log('✅ Approved appointments:', approvedResponse.status);
      console.log('📋 Count:', approvedResponse.data.approvedAppointments?.length || 0);
    } catch (error) {
      console.log('❌ Approved appointments failed:', error.response?.status, error.response?.data);
    }

    // Test 3: Pending appointments
    console.log('\n⏳ Test 3: Pending appointments...');
    try {
      const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });
      console.log('✅ Pending appointments:', pendingResponse.status);
      console.log('📋 Count:', pendingResponse.data.pendingAppointments?.length || 0);
    } catch (error) {
      console.log('❌ Pending appointments failed:', error.response?.status, error.response?.data);
    }

    // Test 4: Emergency records
    console.log('\n🚨 Test 4: Emergency records...');
    try {
      const emergencyResponse = await axios.get(`${BASE_URL}/api/admin/emergencies`, { headers });
      console.log('✅ Emergency records:', emergencyResponse.status);
      console.log('📋 Count:', emergencyResponse.data.emergencyRecords?.length || 0);
    } catch (error) {
      console.log('❌ Emergency records failed:', error.response?.status, error.response?.data);
    }

    // Test 5: All appointments
    console.log('\n📋 Test 5: All appointments...');
    try {
      const allAppointmentsResponse = await axios.get(`${BASE_URL}/api/admin/appointments`, { headers });
      console.log('✅ All appointments:', allAppointmentsResponse.status);
      console.log('📋 Count:', allAppointmentsResponse.data.appointments?.length || 0);
    } catch (error) {
      console.log('❌ All appointments failed:', error.response?.status, error.response?.data);
    }

    // Test 6: Patients
    console.log('\n👥 Test 6: Patients...');
    try {
      const patientsResponse = await axios.get(`${BASE_URL}/api/admin/patients`, { headers });
      console.log('✅ Patients:', patientsResponse.status);
      console.log('📋 Count:', patientsResponse.data.patients?.length || 0);
    } catch (error) {
      console.log('❌ Patients failed:', error.response?.status, error.response?.data);
    }

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testAdminEndpoints(); 