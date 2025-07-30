const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAfterRestart() {
  console.log('🔍 Testing all endpoints after Railway restart...');
  console.log(`🌐 URL: ${BASE_URL}`);
  
  try {
    // Step 1: Test health endpoint
    console.log('\n1️⃣ Testing health endpoint...');
    const healthResponse = await axios.get(`${BASE_URL}/health`);
    console.log('✅ Health endpoint working:', healthResponse.status);
    
    // Step 2: Test admin login
    console.log('\n2️⃣ Testing admin login...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    if (loginResponse.status === 200) {
      const token = loginResponse.data.token;
      console.log('✅ Admin login successful');
      
      const headers = {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      };
      
      // Step 3: Test all admin endpoints
      console.log('\n3️⃣ Testing admin endpoints...');
      
      const endpoints = [
        { name: 'Dashboard Stats', url: '/api/admin/dashboard' },
        { name: 'All Appointments', url: '/api/admin/appointments' },
        { name: 'Pending Appointments', url: '/api/admin/appointments/pending' },
        { name: 'Approved Appointments', url: '/api/admin/appointments/approved' },
        { name: 'Completed Appointments', url: '/api/admin/appointments/completed' },
        { name: 'Patients', url: '/api/admin/patients' },
        { name: 'Emergency Records', url: '/api/admin/emergency-records' }
      ];
      
      for (const endpoint of endpoints) {
        try {
          console.log(`\n🔍 Testing: ${endpoint.name}`);
          const response = await axios.get(`${BASE_URL}${endpoint.url}`, { headers });
          console.log(`✅ ${endpoint.name}: ${response.status} - ${Array.isArray(response.data) ? response.data.length + ' items' : 'OK'}`);
          
          // Show sample data for pending appointments
          if (endpoint.name === 'Pending Appointments' && response.data.length > 0) {
            console.log('📋 Sample pending appointment:', {
              id: response.data[0].id,
              patientName: response.data[0].patientName,
              service: response.data[0].service,
              appointmentDate: response.data[0].appointmentDate
            });
          }
          
        } catch (error) {
          console.log(`❌ ${endpoint.name}: ${error.response?.status || error.message}`);
        }
      }
      
      // Step 4: Test patient endpoints
      console.log('\n4️⃣ Testing patient endpoints...');
      try {
        const patientsResponse = await axios.get(`${BASE_URL}/api/patients`, { headers });
        console.log(`✅ Patients endpoint: ${patientsResponse.status} - ${patientsResponse.data.length} patients`);
      } catch (error) {
        console.log(`❌ Patients endpoint: ${error.response?.status || error.message}`);
      }
      
      // Step 5: Test survey endpoints
      console.log('\n5️⃣ Testing survey endpoints...');
      try {
        const surveysResponse = await axios.get(`${BASE_URL}/api/surveys`, { headers });
        console.log(`✅ Surveys endpoint: ${surveysResponse.status} - ${surveysResponse.data.length} surveys`);
      } catch (error) {
        console.log(`❌ Surveys endpoint: ${error.response?.status || error.message}`);
      }
      
      console.log('\n🎉 All tests completed!');
      console.log('\n📱 Next steps:');
      console.log('1. Open your Flutter app');
      console.log('2. Login as admin');
      console.log('3. Go to admin dashboard');
      console.log('4. Check if pending appointments are now visible');
      
    } else {
      console.log('❌ Admin login failed:', loginResponse.status);
    }
    
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    if (error.response) {
      console.error('Response status:', error.response.status);
      console.error('Response data:', error.response.data);
    }
  }
}

testAfterRestart(); 