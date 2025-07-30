const https = require('https');

// Test vincent1@gmail.com account and survey submission
async function testVincentAccount() {
  console.log('🔍 Testing vincent1@gmail.com account...');
  
  try {
    // Step 1: Test login with vincent1@gmail.com
    console.log('\n1. Testing login with vincent1@gmail.com...');
    const loginData = JSON.stringify({
      email: 'vincent1@gmail.com',
      password: 'password123'
    });
    
    const loginResponse = await makeRequest('/api/auth/login', 'POST', loginData);
    console.log('Login status:', loginResponse.statusCode);
    console.log('Login response:', loginResponse.data);
    
    if (loginResponse.statusCode !== 200) {
      console.log('❌ Login failed - account may not exist');
      return;
    }
    
    const token = loginResponse.data.token;
    console.log('✅ Login successful, token received');
    
    // Step 2: Test survey submission with authenticated token
    console.log('\n2. Testing survey submission with authenticated token...');
    const surveyData = JSON.stringify({
      surveyData: {
        patient_info: {
          name: 'Vincent Test',
          email: 'vincent1@gmail.com',
          serial_number: 'VIN001',
          unit_assignment: 'Test Unit',
          contact_number: '09123456789',
          emergency_contact: 'Emergency Contact',
          emergency_phone: '09123456789',
          classification: 'Others',
          other_classification: 'Test',
          last_visit: 'JULY 29'
        },
        tooth_conditions: {
          decayed_tooth: false,
          worn_down_tooth: false,
          impacted_tooth: false
        },
        tartar_level: 'LIGHT',
        tooth_pain: false,
        tooth_sensitive: false,
        damaged_fillings: {
          broken_tooth: false,
          broken_pasta: false
        },
        need_dentures: false,
        has_missing_teeth: false,
        missing_tooth_conditions: {
          missing_broken_pasta: null,
          missing_broken_tooth: null
        }
      }
    });
    
    const surveyResponse = await makeRequest('/api/surveys', 'POST', surveyData, token);
    console.log('Survey submission status:', surveyResponse.statusCode);
    console.log('Survey response:', surveyResponse.data);
    
    if (surveyResponse.statusCode === 200) {
      console.log('\n🎉 Survey submission successful with vincent1@gmail.com!');
      console.log('✅ This account is working correctly');
    } else {
      console.log('\n❌ Survey submission failed with authenticated account');
      console.log('📋 This suggests the issue is with the database, not the account');
    }
    
  } catch (error) {
    console.error('❌ Error testing vincent account:', error.message);
  }
}

// Step 3: Test kiosk mode for comparison
async function testKioskMode() {
  console.log('\n3. Testing kiosk mode for comparison...');
  
  try {
    const kioskSurveyData = JSON.stringify({
      surveyData: {
        patient_info: {
          name: 'Kiosk Test',
          email: 'kiosk@test.com'
        },
        submitted_at: new Date().toISOString(),
        submitted_via: 'kiosk'
      }
    });
    
    const kioskResponse = await makeRequest('/api/surveys', 'POST', kioskSurveyData, 'kiosk_token');
    console.log('Kiosk survey status:', kioskResponse.statusCode);
    console.log('Kiosk response:', kioskResponse.data);
    
    if (kioskResponse.statusCode === 200) {
      console.log('✅ Kiosk mode working');
    } else {
      console.log('❌ Kiosk mode also failing');
    }
    
  } catch (error) {
    console.error('❌ Error testing kiosk mode:', error.message);
  }
}

function makeRequest(path, method = 'GET', data = null, token = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'afp-dental-app-production.up.railway.app',
      port: 443,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    if (data) {
      options.headers['Content-Length'] = Buffer.byteLength(data);
    }

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const jsonResponse = JSON.parse(responseData);
          resolve({ statusCode: res.statusCode, data: jsonResponse });
        } catch (e) {
          resolve({ statusCode: res.statusCode, data: responseData });
        }
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

// Run the tests
async function runTests() {
  await testVincentAccount();
  await testKioskMode();
  
  console.log('\n📊 Test Summary:');
  console.log('• If vincent1@gmail.com login fails: Account doesn\'t exist');
  console.log('• If login works but survey fails: Database issue (needs kiosk patient)');
  console.log('• If both work: Account is fine, issue was with kiosk mode');
}

runTests()
  .then(() => {
    console.log('\n✅ Account testing completed');
  })
  .catch(error => {
    console.error('\n❌ Account testing failed:', error);
  }); 