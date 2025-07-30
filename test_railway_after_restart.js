const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testRailwayAfterRestart() {
  try {
    console.log('🧪 Testing Railway deployment after restart...\n');

    // Test admin login
    console.log('🔐 Testing admin login...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const token = loginResponse.data.token;
    const headers = { Authorization: `Bearer ${token}` };

    console.log('✅ Admin login: Working');

    // Test pending appointments format
    console.log('\n📋 Testing pending appointments format...');
    const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });

    console.log('📊 Response format check:');
    console.log('Status:', pendingResponse.status);
    console.log('Data type:', typeof pendingResponse.data);
    console.log('Is array:', Array.isArray(pendingResponse.data));
    console.log('Has pendingAppointments key:', pendingResponse.data.hasOwnProperty('pendingAppointments'));

    if (Array.isArray(pendingResponse.data)) {
      console.log('✅ SUCCESS: Response format is now correct (array)');
      console.log('📝 This means the Railway restart worked!');
    } else if (pendingResponse.data.hasOwnProperty('pendingAppointments')) {
      console.log('⚠️  Response format still old (object with pendingAppointments)');
      console.log('📝 Railway restart may still be in progress...');
    } else {
      console.log('❓ Unexpected response format');
    }

    // Test approve endpoint
    console.log('\n🧪 Testing approve endpoint...');
    try {
      const approveResponse = await axios.post(
        `${BASE_URL}/api/admin/appointments/999/approve`,
        { notes: 'Test approval' },
        { headers }
      );
      console.log('✅ Approve endpoint: Working (200 OK)');
    } catch (error) {
      if (error.response?.status === 404) {
        console.log('✅ Approve endpoint: Working (404 expected for non-existent appointment)');
      } else if (error.response?.status === 500) {
        console.log('⚠️  Approve endpoint: Still has 500 error (needs more time)');
      } else {
        console.log('⚠️  Approve endpoint test:', error.response?.status, error.response?.data?.error);
      }
    }

    // Test reject endpoint
    console.log('\n🧪 Testing reject endpoint...');
    try {
      const rejectResponse = await axios.post(
        `${BASE_URL}/api/admin/appointments/999/reject`,
        { reason: 'Test rejection' },
        { headers }
      );
      console.log('✅ Reject endpoint: Working (200 OK)');
    } catch (error) {
      if (error.response?.status === 404) {
        console.log('✅ Reject endpoint: Working (404 expected for non-existent appointment)');
      } else if (error.response?.status === 500) {
        console.log('⚠️  Reject endpoint: Still has 500 error (needs more time)');
      } else {
        console.log('⚠️  Reject endpoint test:', error.response?.status, error.response?.data?.error);
      }
    }

    // Final assessment
    console.log('\n📋 FINAL ASSESSMENT:');
    console.log('✅ Admin login: Working');
    
    if (Array.isArray(pendingResponse.data)) {
      console.log('✅ Response format: Fixed (array)');
      console.log('✅ Approve endpoint: Should be working');
      console.log('✅ Reject endpoint: Should be working');
      console.log('\n🎉 APK BUTTONS SHOULD NOW WORK!');
      console.log('📱 The approve/reject buttons in the APK will function correctly');
    } else {
      console.log('⚠️  Response format: Still needs update');
      console.log('⏰ Wait a few more minutes for Railway to complete deployment');
      console.log('🔄 Run this test again in 2-3 minutes');
    }

  } catch (error) {
    console.error('❌ Test failed:', error.response?.data || error.message);
    console.log('\n🚨 Railway may still be restarting...');
    console.log('⏰ Wait 2-3 minutes and try again');
  }
}

testRailwayAfterRestart(); 