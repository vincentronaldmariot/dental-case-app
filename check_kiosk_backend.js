const https = require('https');

console.log('🔍 CHECKING KIOSK BACKEND & DATABASE');
console.log('=====================================\n');

console.log('📊 Testing kiosk survey submission...\n');

async function checkKioskBackend() {
  try {
    console.log('🔍 Step 1: Testing Survey Submission Endpoint');
    
    // Test survey submission with kiosk token
    const surveyData = {
      surveyData: {
        patient_info: {
          name: 'Kiosk Test User',
          email: 'kiosk@test.com'
        },
        questions: {
          q7: 'Yes',
          q8: '1983'
        },
        submitted_at: new Date().toISOString(),
        submitted_via: 'kiosk'
      }
    };

    const response = await makeRequest('/api/surveys', 'POST', JSON.stringify(surveyData), 'kiosk_token');
    
    console.log('📋 Survey Submission Response:');
    console.log('Status Code:', response.statusCode);
    console.log('Response:', JSON.stringify(response.data, null, 2));
    
    if (response.statusCode === 200) {
      console.log('✅ Survey submission successful!');
      console.log('🎉 The kiosk patient fix is working!');
    } else if (response.statusCode === 500) {
      console.log('❌ Still getting 500 error');
      console.log('🔧 Need to add FIX_KIOSK_PATIENT variable');
    } else {
      console.log('⚠️ Unexpected status:', response.statusCode);
    }

    console.log('\n🔍 Step 2: Testing Health Endpoint');
    
    const healthResponse = await makeRequest('/health', 'GET');
    console.log('Health Status:', healthResponse.statusCode);
    
    if (healthResponse.statusCode === 200) {
      console.log('✅ Backend is running');
    } else {
      console.log('❌ Backend might be down');
    }

    console.log('\n🔍 Step 3: Testing Database Connection');
    
    // Test if we can access the database through the API
    const dbTestResponse = await makeRequest('/api/surveys', 'GET', null, 'kiosk_token');
    console.log('Database Test Status:', dbTestResponse.statusCode);
    
    if (dbTestResponse.statusCode === 200) {
      console.log('✅ Database connection working');
    } else {
      console.log('❌ Database connection issue');
    }

  } catch (error) {
    console.log('❌ Error testing backend:', error.message);
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

checkKioskBackend()
  .then(() => {
    console.log('\n🎯 DIAGNOSIS:');
    console.log('If still getting 500 error:');
    console.log('1. Add FIX_KIOSK_PATIENT=true to Railway Variables');
    console.log('2. Restart the Node.js service');
    console.log('3. Test survey submission again');
  })
  .catch(error => {
    console.error('\n❌ Error:', error);
  }); 