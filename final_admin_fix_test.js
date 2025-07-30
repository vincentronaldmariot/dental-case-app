const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function finalAdminFixTest() {
  console.log('🔍 Final Admin Dashboard Fix Test...\n');

  try {
    // Test 1: Admin login
    console.log('📡 Test 1: Admin login...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    if (loginResponse.status !== 200) {
      console.log('❌ Admin login failed:', loginResponse.status);
      return;
    }

    const token = loginResponse.data.token;
    console.log('✅ Admin login successful');

    const headers = {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    };

    // Test 2: Try each admin endpoint individually
    console.log('\n📊 Test 2: Testing individual admin endpoints...');

    const endpoints = [
      { name: 'Dashboard', path: '/api/admin/dashboard' },
      { name: 'Patients', path: '/api/admin/patients' },
      { name: 'All Appointments', path: '/api/admin/appointments' },
      { name: 'Approved Appointments', path: '/api/admin/appointments/approved' },
      { name: 'Pending Appointments', path: '/api/admin/appointments/pending' },
      { name: 'Emergency Records', path: '/api/admin/emergencies' }
    ];

    for (const endpoint of endpoints) {
      try {
        const response = await axios.get(`${BASE_URL}${endpoint.path}`, { headers });
        console.log(`✅ ${endpoint.name}: ${response.status}`);
        
        // If it's the dashboard, show the stats
        if (endpoint.name === 'Dashboard' && response.data.stats) {
          console.log(`📈 Stats: ${JSON.stringify(response.data.stats, null, 2)}`);
        }
      } catch (error) {
        console.log(`❌ ${endpoint.name}: ${error.response?.status} - ${error.response?.data?.error || 'Unknown error'}`);
      }
    }

    console.log('\n📋 Summary:');
    console.log('- If all endpoints show ✅, the fix was successful!');
    console.log('- If some endpoints show ❌, there are still issues');
    console.log('- Check the specific error messages for clues');

    console.log('\n🎯 Next Steps:');
    console.log('- If all tests pass: Your admin dashboard should work!');
    console.log('- If tests fail: Check Railway logs for specific database errors');
    console.log('- Try accessing the admin dashboard in your Flutter app');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

finalAdminFixTest(); 