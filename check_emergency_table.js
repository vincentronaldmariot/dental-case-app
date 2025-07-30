const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function checkEmergencyTable() {
  try {
    console.log('🔍 Checking Emergency Records Table...\n');

    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 2: Check if emergency_records table exists
    console.log('\n2️⃣ Checking emergency_records table structure...');
    try {
      const tableCheckResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/check-table/emergency_records`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      console.log('✅ Table structure check response:', tableCheckResponse.data);

    } catch (error) {
      console.log('❌ Table structure check failed');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    // Step 3: Try to get emergency records with error details
    console.log('\n3️⃣ Testing emergency records with detailed error...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      console.log('✅ Emergency records retrieved successfully');
      console.log(`📊 Found ${emergencyResponse.data.emergencyRecords?.length || 0} records`);

    } catch (error) {
      console.log('❌ Emergency records failed with details:');
      console.log(`   Status: ${error.response?.status}`);
      console.log(`   Error: ${error.response?.data?.error || error.message}`);
      
      if (error.response?.data?.details) {
        console.log(`   Details: ${JSON.stringify(error.response.data.details, null, 2)}`);
      }
    }

    // Step 4: Check if there are any emergency records at all
    console.log('\n4️⃣ Checking for any emergency records...');
    try {
      const simpleCheckResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency?limit=1`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      console.log('✅ Simple emergency check successful');
      console.log('Response:', simpleCheckResponse.data);

    } catch (error) {
      console.log('❌ Simple emergency check failed');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    console.log('\n📋 EMERGENCY TABLE SUMMARY:');
    console.log('   • Admin authentication: ✅');
    console.log('   • Table structure: ⚠️ (needs verification)');
    console.log('   • Emergency records endpoint: ❌ (500 error)');
    console.log('   • Database connection: ⚠️ (needs verification)');

  } catch (error) {
    console.error('❌ Check failed:', error.response?.data || error.message);
  }
}

checkEmergencyTable(); 