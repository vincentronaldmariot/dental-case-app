const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testFlutterSimulation() {
  try {
    console.log('🔍 Simulating Flutter app behavior...');
    
    // Step 1: Login as admin (like Flutter app does)
    console.log('\n1️⃣ Admin login (Flutter simulation)...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    if (loginResponse.status === 200) {
      const token = loginResponse.data.token;
      console.log('✅ Admin login successful');
      console.log('Token received:', token ? 'Yes' : 'No');
      
      const headers = {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      };
      
      // Step 2: Call pending appointments endpoint (like Flutter app does)
      console.log('\n2️⃣ Calling pending appointments endpoint...');
      const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers });
      
      if (pendingResponse.status === 200) {
        const data = pendingResponse.data;
        console.log('✅ Pending appointments endpoint successful');
        console.log('Response type:', typeof data);
        console.log('Is array:', Array.isArray(data));
        
        // Simulate Flutter app's data extraction logic
        let appointments = [];
        if (Array.isArray(data)) {
          appointments = data;
          console.log('📋 Using direct array response');
        } else if (data && typeof data === 'object' && data.pendingAppointments) {
          appointments = data.pendingAppointments || [];
          console.log('📋 Using pendingAppointments from object response');
        } else if (data && typeof data === 'object') {
          appointments = [data];
          console.log('📋 Using single object as array');
        }
        
        console.log(`📊 Extracted ${appointments.length} pending appointments`);
        
        if (appointments.length > 0) {
          console.log('\n📋 Pending appointments found:');
          appointments.forEach((apt, index) => {
            console.log(`  ${index + 1}. ID: ${apt.id}`);
            console.log(`     Patient: ${apt.patientName}`);
            console.log(`     Service: ${apt.service}`);
            console.log(`     Date: ${apt.appointmentDate}`);
            console.log(`     Status: ${apt.status}`);
            console.log('');
          });
        } else {
          console.log('📭 No pending appointments extracted');
        }
        
        // Step 3: Test if this would show in Flutter UI
        console.log('\n3️⃣ Flutter UI simulation:');
        if (appointments.length > 0) {
          console.log('✅ Pending appointments WOULD be visible in Flutter admin dashboard');
          console.log('✅ The issue is NOT with the backend or data extraction');
        } else {
          console.log('❌ Pending appointments would NOT be visible in Flutter admin dashboard');
          console.log('❌ This suggests the issue is with data extraction or backend response');
        }
        
      } else {
        console.log('❌ Pending appointments endpoint failed:', pendingResponse.status);
      }
      
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

testFlutterSimulation(); 