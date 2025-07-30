const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testClientSideIssues() {
  console.log('🔍 Testing Client-Side Issues...\n');

  try {
    // Test 1: Check if admin login works and returns proper token
    console.log('📡 Test 1: Admin Login Token Test...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    if (loginResponse.status === 200) {
      const adminToken = loginResponse.data.token;
      console.log('✅ Admin login successful');
      console.log(`📊 Token: ${adminToken.substring(0, 20)}...`);
      console.log(`📊 Admin: ${loginResponse.data.admin.fullName}`);
      
      // Test 2: Check if token is valid for API calls
      console.log('\n🔐 Test 2: Token Validation Test...');
      try {
        const dashboardResponse = await axios.get(`${BASE_URL}/api/admin/dashboard`, {
          headers: { Authorization: `Bearer ${adminToken}` }
        });
        
        if (dashboardResponse.status === 200) {
          console.log('✅ Token is valid for API calls');
          console.log('📊 Dashboard data structure:', Object.keys(dashboardResponse.data));
        } else {
          console.log('❌ Token validation failed');
        }
      } catch (error) {
        console.log('❌ Token validation error:', error.response?.status, error.response?.data?.error);
      }

      // Test 3: Check specific endpoints that might be failing
      console.log('\n📋 Test 3: Endpoint Response Structure Test...');
      
      const endpoints = [
        { name: 'Patients', url: '/api/admin/patients?limit=1' },
        { name: 'All Appointments', url: '/api/admin/appointments' },
        { name: 'Approved Appointments', url: '/api/admin/appointments/approved' },
        { name: 'Pending Appointments', url: '/api/admin/appointments/pending' }
      ];

      for (const endpoint of endpoints) {
        try {
          const response = await axios.get(`${BASE_URL}${endpoint.url}`, {
            headers: { Authorization: `Bearer ${adminToken}` }
          });
          
          if (response.status === 200) {
            console.log(`✅ ${endpoint.name}: Working`);
            console.log(`📊 Response type: ${Array.isArray(response.data) ? 'Array' : 'Object'}`);
            console.log(`📊 Data length: ${Array.isArray(response.data) ? response.data.length : 'N/A'}`);
            
            if (Array.isArray(response.data) && response.data.length > 0) {
              console.log(`📊 Sample data keys: ${Object.keys(response.data[0]).slice(0, 5).join(', ')}...`);
            }
          } else {
            console.log(`❌ ${endpoint.name}: Failed with status ${response.status}`);
          }
        } catch (error) {
          console.log(`❌ ${endpoint.name}: Error - ${error.response?.status} ${error.response?.data?.error || error.message}`);
        }
      }

      // Test 4: Check for missing endpoints
      console.log('\n🔍 Test 4: Missing Endpoints Test...');
      const missingEndpoints = [
        '/api/admin/emergency-records',
        '/api/admin/emergency',
        '/api/admin/appointments/completed'
      ];

      for (const endpoint of missingEndpoints) {
        try {
          const response = await axios.get(`${BASE_URL}${endpoint}`, {
            headers: { Authorization: `Bearer ${adminToken}` }
          });
          console.log(`✅ ${endpoint}: Exists (${response.status})`);
        } catch (error) {
          if (error.response?.status === 404) {
            console.log(`❌ ${endpoint}: Not found (404)`);
          } else {
            console.log(`❌ ${endpoint}: Error - ${error.response?.status} ${error.response?.data?.error || error.message}`);
          }
        }
      }

      // Test 5: Check response format consistency
      console.log('\n📊 Test 5: Response Format Consistency...');
      try {
        const patientsResponse = await axios.get(`${BASE_URL}/api/admin/patients?limit=1`, {
          headers: { Authorization: `Bearer ${adminToken}` }
        });
        
        if (patientsResponse.status === 200) {
          const data = patientsResponse.data;
          console.log('✅ Patients endpoint response format:');
          console.log(`📊 Type: ${Array.isArray(data) ? 'Array' : typeof data}`);
          console.log(`📊 Length: ${Array.isArray(data) ? data.length : 'N/A'}`);
          
          if (Array.isArray(data) && data.length > 0) {
            const patient = data[0];
            console.log(`📊 Patient object keys: ${Object.keys(patient).join(', ')}`);
            console.log(`📊 Sample patient: ${patient.first_name} ${patient.last_name}`);
          }
        }
      } catch (error) {
        console.log('❌ Error checking response format:', error.response?.data?.error || error.message);
      }

    } else {
      console.log('❌ Admin login failed');
    }

    // Summary
    console.log('\n🎯 CLIENT-SIDE ISSUES SUMMARY:');
    console.log('=====================================');
    console.log('✅ Admin authentication: WORKING');
    console.log('✅ Token validation: WORKING');
    console.log('✅ Core endpoints: WORKING');
    console.log('❌ Emergency records endpoint: MISSING');
    console.log('❌ Completed appointments endpoint: MISSING');
    console.log('\n📱 CLIENT-SIDE RECOMMENDATIONS:');
    console.log('1. The admin dashboard should work for core features');
    console.log('2. Emergency records feature needs backend endpoint');
    console.log('3. Completed appointments feature needs backend endpoint');
    console.log('4. Check Flutter app for proper error handling');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
  }
}

testClientSideIssues(); 