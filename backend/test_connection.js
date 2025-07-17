const http = require('http');

console.log('Testing backend connection...\n');

// Test 1: Health endpoint
console.log('1. Testing health endpoint...');
const healthOptions = {
  hostname: 'localhost',
  port: 3000,
  path: '/health',
  method: 'GET'
};

http.request(healthOptions, (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    console.log('   Status:', res.statusCode);
    console.log('   Response:', data);
    console.log('   ✅ Health endpoint working\n');
    
    // Test 2: Admin login
    testAdminLogin();
  });
}).on('error', (err) => {
  console.log('   ❌ Health endpoint failed:', err.message);
}).end();

function testAdminLogin() {
  console.log('2. Testing admin login...');
  const loginData = JSON.stringify({
    username: 'admin',
    password: 'admin123'
  });

  const loginOptions = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/admin/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(loginData)
    }
  };

  const req = http.request(loginOptions, (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      console.log('   Status:', res.statusCode);
      if (res.statusCode === 200) {
        const response = JSON.parse(data);
        console.log('   ✅ Admin login successful');
        console.log('   Token received:', response.token.substring(0, 50) + '...\n');
        
        // Test 3: Pending appointments
        testPendingAppointments(response.token);
      } else {
        console.log('   ❌ Admin login failed:', data);
      }
    });
  });
  
  req.on('error', (err) => {
    console.log('   ❌ Admin login error:', err.message);
  });
  
  req.write(loginData);
  req.end();
}

function testPendingAppointments(token) {
  console.log('3. Testing pending appointments...');
  const pendingOptions = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/admin/appointments/pending',
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  };

  http.request(pendingOptions, (res) => {
    let data = '';
    res.on('data', (chunk) => data += chunk);
    res.on('end', () => {
      console.log('   Status:', res.statusCode);
      if (res.statusCode === 200) {
        const response = JSON.parse(data);
        console.log('   ✅ Pending appointments endpoint working');
        console.log(`   Found ${response.pendingAppointments.length} pending appointments`);
        console.log('   Pagination:', response.pagination);
        console.log('\n   📋 Pending appointments:');
        response.pendingAppointments.forEach((apt, index) => {
          console.log(`   ${index + 1}. ${apt.patientName} - ${apt.service} - ${apt.appointmentDate}`);
        });
      } else {
        console.log('   ❌ Pending appointments failed:', data);
      }
    });
  }).on('error', (err) => {
    console.log('   ❌ Pending appointments error:', err.message);
  }).end();
} 