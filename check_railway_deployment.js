const https = require('https');

async function checkRailwayDeployment() {
  console.log('🔍 Checking Railway deployment status...');
  
  try {
    // Test 1: Check if server is running
    console.log('\n1. Testing server health...');
    const healthResponse = await makeRequest('/health');
    console.log('Health check:', healthResponse.statusCode === 200 ? '✅ OK' : '❌ Failed');
    
    // Test 2: Check if new error handling is working
    console.log('\n2. Testing survey endpoint with new error handling...');
    const testData = JSON.stringify({
      surveyData: {
        patient_info: {
          name: 'Test Deployment',
          email: 'test@deployment.com'
        },
        submitted_at: new Date().toISOString(),
        submitted_via: 'kiosk'
      }
    });
    
    const surveyResponse = await makeRequest('/api/surveys', 'POST', testData);
    console.log('Survey test status:', surveyResponse.statusCode);
    console.log('Survey response:', surveyResponse.data);
    
    if (surveyResponse.statusCode === 500) {
      console.log('\n❌ Still getting 500 error - database fix needed');
      console.log('📋 Next steps:');
      console.log('1. Access Railway database via dashboard');
      console.log('2. Run the kiosk patient creation SQL');
      console.log('3. Test survey submission again');
    } else if (surveyResponse.statusCode === 200) {
      console.log('\n✅ Survey submission working!');
    }
    
  } catch (error) {
    console.error('❌ Error checking deployment:', error.message);
  }
}

function makeRequest(path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'afp-dental-app-production.up.railway.app',
      port: 443,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer kiosk_token'
      }
    };

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

checkRailwayDeployment()
  .then(() => {
    console.log('\n✅ Deployment check completed');
  })
  .catch(error => {
    console.error('\n❌ Deployment check failed:', error);
  }); 