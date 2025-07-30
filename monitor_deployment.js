const https = require('https');

// Monitor Railway deployment
async function monitorDeployment() {
  console.log('🔍 Monitoring Railway deployment...');
  console.log('⏰ Checking every 2 minutes for deployment completion');
  console.log('📱 Use this account: vincent1@gmail.com / password123');
  console.log('');
  
  let attempts = 0;
  const maxAttempts = 15; // 30 minutes total
  
  const checkDeployment = async () => {
    attempts++;
    console.log(`\n🔄 Attempt ${attempts}/${maxAttempts} - Checking deployment...`);
    
    try {
      const response = await makeRequest('/api/surveys', 'POST', JSON.stringify({
        surveyData: {
          patient_info: {
            name: 'Deployment Test',
            email: 'deployment@test.com'
          },
          submitted_at: new Date().toISOString(),
          submitted_via: 'kiosk'
        }
      }), 'kiosk_token');
      
      console.log('Status:', response.statusCode);
      
      if (response.statusCode === 200) {
        console.log('\n🎉 DEPLOYMENT COMPLETE!');
        console.log('✅ Survey submission is now working!');
        console.log('📱 Your Flutter app should work perfectly now');
        console.log('🚀 You can test the survey submission in your app');
        return true;
      } else if (response.statusCode === 500) {
        console.log('❌ Still deploying... (500 error)');
        console.log('📋 Waiting for automatic kiosk patient creation...');
      } else {
        console.log(`⚠️ Unexpected status: ${response.statusCode}`);
      }
      
    } catch (error) {
      console.log('❌ Connection error - still deploying...');
    }
    
    if (attempts >= maxAttempts) {
      console.log('\n⏰ 30 minutes elapsed - deployment may need manual intervention');
      console.log('📋 Consider using Option 2 (external database tool)');
      return true;
    }
    
    return false;
  };
  
  // Check immediately
  let completed = await checkDeployment();
  
  // Then check every 2 minutes
  while (!completed) {
    await new Promise(resolve => setTimeout(resolve, 120000)); // 2 minutes
    completed = await checkDeployment();
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

// Start monitoring
console.log('🚀 Starting Railway deployment monitor...');
monitorDeployment()
  .then(() => {
    console.log('\n✅ Deployment monitoring completed');
  })
  .catch(error => {
    console.error('\n❌ Deployment monitoring failed:', error);
  }); 