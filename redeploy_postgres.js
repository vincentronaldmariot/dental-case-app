const https = require('https');

console.log('🗄️ POSTGRESQL REDEPLOYMENT OPTIONS');
console.log('=====================================\n');

console.log('🔧 Option 1: Railway Dashboard (Recommended)');
console.log('1. Go to Railway dashboard: https://railway.app/dashboard');
console.log('2. Click on your project');
console.log('3. Find the PostgreSQL service');
console.log('4. Click on the PostgreSQL service');
console.log('5. Go to "Settings" tab');
console.log('6. Click "Redeploy" or "Restart"');
console.log('7. Wait for restart to complete\n');

console.log('🔧 Option 2: Railway CLI');
console.log('1. Install Railway CLI: npm install -g @railway/cli');
console.log('2. Login: railway login');
console.log('3. Link project: railway link');
console.log('4. Restart service: railway service restart\n');

console.log('🔧 Option 3: Manual Database Reset');
console.log('1. Go to Railway dashboard');
console.log('2. Click on PostgreSQL service');
console.log('3. Go to "Data" tab');
console.log('4. Click "Reset Database" (⚠️ This will delete all data)');
console.log('5. Confirm the reset');
console.log('6. Wait for reset to complete\n');

console.log('🔧 Option 4: Quick Fix via API (Try this first)');
console.log('Running quick fix attempt...\n');

// Try the quick fix
async function quickFix() {
  try {
    console.log('🔧 Attempting quick database fix...');
    
    // Test if the fix endpoint exists
    const response = await makeRequest('/api/admin/fix-kiosk-patient', 'POST', JSON.stringify({}));
    
    if (response.statusCode === 200) {
      console.log('✅ Quick fix successful!');
      console.log('📋 Kiosk patient created via API');
      
      // Test survey submission
      const surveyResponse = await makeRequest('/api/surveys', 'POST', JSON.stringify({
        surveyData: {
          patient_info: { name: 'Test', email: 'test@test.com' },
          submitted_at: new Date().toISOString(),
          submitted_via: 'kiosk'
        }
      }), 'kiosk_token');
      
      if (surveyResponse.statusCode === 200) {
        console.log('🎉 Survey submission working!');
        console.log('✅ Your Flutter app should work now');
      } else {
        console.log('❌ Survey still failing - need database redeploy');
      }
      
    } else if (response.statusCode === 404) {
      console.log('❌ Admin endpoint not found');
      console.log('📋 Need to redeploy PostgreSQL or wait for deployment');
      
    } else {
      console.log(`⚠️ Unexpected response: ${response.statusCode}`);
    }
    
  } catch (error) {
    console.log('❌ Quick fix failed:', error.message);
    console.log('📋 Need manual database redeploy');
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

// Run quick fix
quickFix()
  .then(() => {
    console.log('\n📋 RECOMMENDED ACTION:');
    console.log('If quick fix failed, use Option 1 (Railway Dashboard) to redeploy PostgreSQL');
    console.log('This will restart the database and apply the latest schema');
  })
  .catch(error => {
    console.error('\n❌ Error:', error);
  }); 