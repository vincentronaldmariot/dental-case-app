const axios = require('axios');

async function testOnlineServerDebug() {
  try {
    console.log('🧪 Debugging online Railway server response...');
    
    const onlineUrl = 'https://afp-dental-app-production.up.railway.app';
    
    // Login as admin
    console.log('📝 Logging in as admin...');
    const adminLoginResponse = await axios.post(`${onlineUrl}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');
    
    // Test pending appointments endpoint with detailed logging
    console.log('\n📝 Testing pending appointments endpoint...');
    const pendingResponse = await axios.get(`${onlineUrl}/api/admin/appointments/pending`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Raw response details:');
    console.log('📊 Status:', pendingResponse.status);
    console.log('📊 Headers:', JSON.stringify(pendingResponse.headers, null, 2));
    console.log('📊 Response type:', typeof pendingResponse.data);
    console.log('📊 Is array:', Array.isArray(pendingResponse.data));
    console.log('📊 Response keys:', Object.keys(pendingResponse.data));
    console.log('📊 Full response data:', JSON.stringify(pendingResponse.data, null, 2));
    
    // Also test the alternative endpoint
    console.log('\n📝 Testing alternative pending appointments endpoint...');
    const pendingAltResponse = await axios.get(`${onlineUrl}/api/admin/pending-appointments`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Alternative endpoint response:');
    console.log('📊 Status:', pendingAltResponse.status);
    console.log('📊 Response type:', typeof pendingAltResponse.data);
    console.log('📊 Is array:', Array.isArray(pendingAltResponse.data));
    console.log('📊 Response keys:', Object.keys(pendingAltResponse.data));
    console.log('📊 Full response data:', JSON.stringify(pendingAltResponse.data, null, 2));
    
  } catch (error) {
    console.error('❌ Test failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Headers:', error.response.headers);
      console.error('Data:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
  }
}

testOnlineServerDebug(); 