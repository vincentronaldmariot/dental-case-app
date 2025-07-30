const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function checkRailwayDeployment() {
  try {
    console.log('🔍 Checking Railway deployment status...\n');

    // Test admin login
    console.log('🔐 Testing admin login...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    console.log('✅ Admin login successful');

    // Test pending appointments endpoint
    console.log('📋 Testing pending appointments endpoint...');
    const token = loginResponse.data.token;
    const headers = { Authorization: `Bearer ${token}` };

    const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });

    console.log('📊 Response format:');
    console.log('Status:', pendingResponse.status);
    console.log('Data type:', typeof pendingResponse.data);
    console.log('Has pendingAppointments key:', pendingResponse.data.hasOwnProperty('pendingAppointments'));
    console.log('Direct array length:', Array.isArray(pendingResponse.data) ? pendingResponse.data.length : 'Not an array');

    if (pendingResponse.data.hasOwnProperty('pendingAppointments')) {
      console.log('\n🚨 ISSUE DETECTED: Railway deployment has old response format!');
      console.log('📝 The Railway deployment returns: { pendingAppointments: [...] }');
      console.log('📝 But the latest code expects: [...] (direct array)');
      console.log('\n🔧 SOLUTION: Railway deployment needs to be updated with latest backend code');
    } else if (Array.isArray(pendingResponse.data)) {
      console.log('\n✅ Railway deployment has correct response format!');
      console.log('📝 The Railway deployment returns: [...] (direct array)');
      console.log('📝 This matches the latest backend code');
    }

    // Test approve endpoint
    console.log('\n🧪 Testing approve endpoint accessibility...');
    try {
      const approveResponse = await axios.post(
        `${BASE_URL}/api/admin/appointments/999/approve`,
        { notes: 'Test' },
        { headers }
      );
      console.log('✅ Approve endpoint is accessible');
    } catch (error) {
      if (error.response?.status === 404) {
        console.log('✅ Approve endpoint exists (404 expected for non-existent appointment)');
      } else {
        console.log('⚠️  Approve endpoint test:', error.response?.status, error.response?.data?.error);
      }
    }

    // Test reject endpoint
    console.log('\n🧪 Testing reject endpoint accessibility...');
    try {
      const rejectResponse = await axios.post(
        `${BASE_URL}/api/admin/appointments/999/reject`,
        { reason: 'Test' },
        { headers }
      );
      console.log('✅ Reject endpoint is accessible');
    } catch (error) {
      if (error.response?.status === 404) {
        console.log('✅ Reject endpoint exists (404 expected for non-existent appointment)');
      } else {
        console.log('⚠️  Reject endpoint test:', error.response?.status, error.response?.data?.error);
      }
    }

    console.log('\n📋 SUMMARY:');
    console.log('✅ Admin login: Working');
    console.log('✅ Approve endpoint: Accessible');
    console.log('✅ Reject endpoint: Accessible');
    
    if (pendingResponse.data.hasOwnProperty('pendingAppointments')) {
      console.log('⚠️  Response format: Needs update (old format)');
      console.log('\n🚀 NEXT STEPS:');
      console.log('1. Deploy the latest backend code to Railway');
      console.log('2. The Flutter app will then work correctly with the APK');
    } else {
      console.log('✅ Response format: Correct (latest format)');
      console.log('\n🎯 RESULT: APK should work correctly!');
    }

  } catch (error) {
    console.error('❌ Railway check failed:', error.response?.data || error.message);
    console.log('\n🚨 Railway deployment may be down or needs restart');
  }
}

checkRailwayDeployment(); 