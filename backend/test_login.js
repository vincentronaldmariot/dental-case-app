const axios = require('axios');
const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testLogins() {
  console.log('🔐 Testing login functionality...\n');
  
  // Test admin login
  try {
    console.log('👨‍💼 Testing admin login...');
    const adminResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    }, {
      timeout: 10000,
      headers: { 'Content-Type': 'application/json' }
    });
    console.log('✅ Admin login successful');
    console.log('   Token:', adminResponse.data.token ? '***RECEIVED***' : 'NOT RECEIVED');
    console.log('   User:', adminResponse.data.admin?.username);
  } catch (error) {
    console.log('❌ Admin login failed');
    console.log('   Status:', error.response?.status);
    console.log('   Error:', error.response?.data?.message || error.message);
  }
  
  console.log('');
  
  // Test patient login
  try {
    console.log('👤 Testing patient login...');
    const patientResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'john.doe@test.com',
      password: 'patient123'
    }, {
      timeout: 10000,
      headers: { 'Content-Type': 'application/json' }
    });
    console.log('✅ Patient login successful');
    console.log('   Token:', patientResponse.data.token ? '***RECEIVED***' : 'NOT RECEIVED');
    console.log('   User:', patientResponse.data.patient?.email);
  } catch (error) {
    console.log('❌ Patient login failed');
    console.log('   Status:', error.response?.status);
    console.log('   Error:', error.response?.data?.message || error.message);
    if (error.response?.data?.details) {
      console.log('   Validation details:', error.response.data.details);
    }
  }
  
  console.log('');
  
  // Test VIP patient login
  try {
    console.log('👑 Testing VIP patient login...');
    const vipResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'vip.person@test.com',
      password: 'vip123'
    }, {
      timeout: 10000,
      headers: { 'Content-Type': 'application/json' }
    });
    console.log('✅ VIP patient login successful');
    console.log('   Token:', vipResponse.data.token ? '***RECEIVED***' : 'NOT RECEIVED');
    console.log('   User:', vipResponse.data.patient?.email);
  } catch (error) {
    console.log('❌ VIP patient login failed');
    console.log('   Status:', error.response?.status);
    console.log('   Error:', error.response?.data?.message || error.message);
    if (error.response?.data?.details) {
      console.log('   Validation details:', error.response.data.details);
    }
  }
  
  console.log('\n🎉 Login testing completed!');
}

testLogins()
  .then(() => { console.log('✅ All tests completed'); })
  .catch(error => { console.log('💥 Test failed:', error.message); });