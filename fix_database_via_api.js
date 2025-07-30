const https = require('https');

// Fix database via API call
async function fixDatabaseViaAPI() {
  console.log('🔧 Fixing database via API...');
  
  try {
    // First, try to call the admin fix endpoint
    const fixData = JSON.stringify({});
    
    const response = await makeRequest('/api/admin/fix-kiosk-patient', 'POST', fixData);
    console.log('Fix response status:', response.statusCode);
    console.log('Fix response:', response.data);
    
    if (response.statusCode === 200) {
      console.log('\n✅ Database fix successful!');
      console.log('📋 Kiosk patient created successfully');
      
      // Test survey submission
      console.log('\n🧪 Testing survey submission...');
      await testSurveySubmission();
      
    } else if (response.statusCode === 404) {
      console.log('\n❌ Admin endpoint not found - Railway still deploying old code');
      console.log('📋 You need to wait for Railway deployment or use manual fix');
      
    } else {
      console.log('\n❌ Database fix failed');
      console.log('📋 Manual intervention needed');
    }
    
  } catch (error) {
    console.error('❌ Error fixing database:', error.message);
    console.log('\n📋 Manual fix required');
  }
}

// Test survey submission
async function testSurveySubmission() {
  try {
    const surveyData = JSON.stringify({
      surveyData: {
        patient_info: {
          name: 'API Fix Test',
          email: 'apifix@test.com'
        },
        submitted_at: new Date().toISOString(),
        submitted_via: 'kiosk'
      }
    });
    
    const response = await makeRequest('/api/surveys', 'POST', surveyData, 'kiosk_token');
    console.log('Survey test status:', response.statusCode);
    console.log('Survey test response:', response.data);
    
    if (response.statusCode === 200) {
      console.log('\n🎉 Survey submission working!');
      console.log('✅ Your Flutter app should now work');
    } else {
      console.log('\n❌ Survey submission still failing');
      console.log('📋 Manual database fix still needed');
    }
    
  } catch (error) {
    console.error('❌ Error testing survey:', error.message);
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

// Run the fix
fixDatabaseViaAPI()
  .then(() => {
    console.log('\n✅ Database fix process completed');
  })
  .catch(error => {
    console.error('\n❌ Database fix process failed:', error);
  }); 