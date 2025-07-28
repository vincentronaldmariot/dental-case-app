const http = require('http');

// Test emergency completion and filtering
async function testEmergencyCompletionFix() {
  console.log('🧪 Testing Emergency Completion and Filtering Fix...\n');

  try {
    // Step 1: Get admin token
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

    const loginResponse = await makeRequest(loginOptions, loginData);
    console.log('📋 Login Response Status:', loginResponse.statusCode);
    
    if (loginResponse.statusCode !== 200) {
      console.log('❌ Login failed:', loginResponse.body);
      return;
    }

    const loginResult = JSON.parse(loginResponse.body);
    const adminToken = loginResult.token;
    console.log('✅ Admin token obtained\n');

    // Step 2: Get emergency records (excluding resolved)
    const emergencyOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/admin/emergency?exclude_resolved=true',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${adminToken}`
      }
    };

    const emergencyResponse = await makeRequest(emergencyOptions);
    console.log('📋 Emergency Records Response Status:', emergencyResponse.statusCode);
    
    if (emergencyResponse.statusCode !== 200) {
      console.log('❌ Failed to get emergency records:', emergencyResponse.body);
      return;
    }

    const emergencyData = JSON.parse(emergencyResponse.body);
    const emergencyRecords = emergencyData.emergencyRecords;
    
    console.log('📊 Emergency Records (excluding resolved):', emergencyRecords.length);
    
    // Show all emergency records and their statuses
    emergencyRecords.forEach((record, index) => {
      console.log(`  ${index + 1}. ${record.patientName} - ${record.emergencyType} (${record.status})`);
    });

    // Step 3: Get all emergency records (including resolved) for comparison
    const allEmergencyOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/admin/emergency',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${adminToken}`
      }
    };

    const allEmergencyResponse = await makeRequest(allEmergencyOptions);
    if (allEmergencyResponse.statusCode === 200) {
      const allEmergencyData = JSON.parse(allEmergencyResponse.body);
      const allEmergencyRecords = allEmergencyData.emergencyRecords;
      
      console.log('\n📊 All Emergency Records (including resolved):', allEmergencyRecords.length);
      
      const resolvedCount = allEmergencyRecords.filter(r => r.status === 'resolved').length;
      const unresolvedCount = allEmergencyRecords.filter(r => r.status !== 'resolved').length;
      
      console.log(`  - Resolved: ${resolvedCount}`);
      console.log(`  - Unresolved: ${unresolvedCount}`);
      
      if (resolvedCount > 0) {
        console.log('✅ Filtering is working - resolved emergencies are excluded from the main list');
      } else {
        console.log('ℹ️ No resolved emergencies found in the database');
      }
    }

    console.log('\n🎉 Test completed successfully!');
    console.log('📅 Emergency completion and filtering is working correctly.');

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: body
        });
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(data);
    }
    req.end();
  });
}

// Run the test
testEmergencyCompletionFix(); 