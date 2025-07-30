const axios = require('axios');

async function testFlutterAdminConnection() {
  try {
    console.log('🧪 Testing Flutter Admin Dashboard Connection...');
    
    const onlineUrl = 'https://afp-dental-app-production.up.railway.app';
    
    // Step 1: Login as admin (exactly like Flutter app does)
    console.log('📝 Step 1: Admin login...');
    const adminLoginResponse = await axios.post(`${onlineUrl}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');
    console.log('📊 Token:', adminToken.substring(0, 20) + '...');
    
    // Step 2: Fetch pending appointments (exactly like Flutter app does)
    console.log('\n📝 Step 2: Fetching pending appointments (Flutter endpoint)...');
    const pendingResponse = await axios.get(`${onlineUrl}/api/admin/appointments/pending`, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Flutter pending appointments response:');
    console.log('📊 Status:', pendingResponse.status);
    console.log('📊 Response type:', typeof pendingResponse.data);
    console.log('📊 Is array:', Array.isArray(pendingResponse.data));
    console.log('📊 Has pendingAppointments key:', pendingResponse.data.hasOwnProperty('pendingAppointments'));
    
    // Simulate Flutter app's data processing
    let appointments = [];
    if (Array.isArray(pendingResponse.data)) {
      appointments = pendingResponse.data;
      console.log('📋 Flutter would use direct array response');
    } else if (pendingResponse.data.hasOwnProperty('pendingAppointments')) {
      appointments = pendingResponse.data.pendingAppointments || [];
      console.log('📋 Flutter would use pendingAppointments from object response');
    } else if (typeof pendingResponse.data === 'object') {
      appointments = [pendingResponse.data];
      console.log('📋 Flutter would use single object as array');
    }
    
    console.log('📊 Flutter would extract ${appointments.length} appointments');
    
    if (appointments.length > 0) {
      console.log('📋 Flutter would display these appointments:');
      appointments.forEach((apt, index) => {
        console.log(`  ${index + 1}. ${apt.patientName} - ${apt.service} - ${apt.appointmentDate} ${apt.timeSlot}`);
        console.log(`     ID: ${apt.id}, Status: ${apt.status}`);
        console.log(`     Has Survey: ${apt.hasSurveyData}`);
        console.log(`     Patient Email: ${apt.patientEmail}`);
        console.log(`     Patient Phone: ${apt.patientPhone}`);
      });
    } else {
      console.log('❌ Flutter would show "No Pending Appointments"');
    }
    
    // Step 3: Test the exact URL that Flutter app uses
    console.log('\n📝 Step 3: Testing exact Flutter app URL...');
    const flutterUrl = `${onlineUrl}/api/admin/appointments/pending`;
    console.log('📊 Flutter app URL:', flutterUrl);
    
    const flutterResponse = await axios.get(flutterUrl, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Flutter app URL response:');
    console.log('📊 Status:', flutterResponse.status);
    console.log('📊 Response length:', JSON.stringify(flutterResponse.data).length);
    console.log('📊 First 200 chars:', JSON.stringify(flutterResponse.data).substring(0, 200));
    
    // Step 4: Test with different user agent (like Flutter)
    console.log('\n📝 Step 4: Testing with Flutter-like headers...');
    const flutterHeadersResponse = await axios.get(flutterUrl, {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json',
        'User-Agent': 'Dart/3.8 (dart:io)',
        'Accept': 'application/json'
      }
    });
    
    console.log('✅ Flutter headers response:');
    console.log('📊 Status:', flutterHeadersResponse.status);
    console.log('📊 Response type:', typeof flutterHeadersResponse.data);
    console.log('📊 Has pendingAppointments key:', flutterHeadersResponse.data.hasOwnProperty('pendingAppointments'));
    
    if (flutterHeadersResponse.data.hasOwnProperty('pendingAppointments')) {
      const flutterAppointments = flutterHeadersResponse.data.pendingAppointments;
      console.log('📊 Total appointments with Flutter headers:', flutterAppointments.length);
    }
    
  } catch (error) {
    console.error('❌ Test failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
      console.error('Headers:', error.response.headers);
    } else {
      console.error('Error:', error.message);
    }
  }
}

testFlutterAdminConnection(); 