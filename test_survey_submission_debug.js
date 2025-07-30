const https = require('https');

// Test survey submission to Railway server
async function testSurveySubmission() {
  const surveyData = {
    patient_info: {
      name: 'Test Patient',
      serial_number: '12345',
      unit_assignment: 'Test Unit',
      contact_number: '09123456789',
      email: 'test@example.com',
      emergency_contact: 'Emergency Contact',
      emergency_phone: '09123456789',
      classification: 'Others',
      other_classification: 'Test',
      last_visit: 'JUNE 29'
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
  };

  const postData = JSON.stringify({
    surveyData: surveyData
  });

  const options = {
    hostname: 'afp-dental-app-production.up.railway.app',
    port: 443,
    path: '/api/surveys',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer kiosk_token',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log('Status Code:', res.statusCode);
        console.log('Headers:', res.headers);
        console.log('Response:', data);
        
        try {
          const jsonResponse = JSON.parse(data);
          resolve({ statusCode: res.statusCode, data: jsonResponse });
        } catch (e) {
          resolve({ statusCode: res.statusCode, data: data });
        }
      });
    });

    req.on('error', (error) => {
      console.error('Request error:', error);
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

// Run the test
testSurveySubmission()
  .then(result => {
    console.log('\n✅ Test completed successfully');
    console.log('Result:', result);
  })
  .catch(error => {
    console.error('\n❌ Test failed:', error);
  }); 