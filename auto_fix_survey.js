const https = require('https');

// Function to make HTTPS request to Railway
function makeRailwayRequest(path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'afp-dental-app-production.up.railway.app',
      port: 443,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer admin_fix_token'
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

// Automated survey fix
async function autoFixSurvey() {
  try {
    console.log('🚀 Starting automated survey fix...');
    
    // Step 1: Check if server is running
    console.log('\n1. Checking server health...');
    const healthResponse = await makeRailwayRequest('/health');
    if (healthResponse.statusCode !== 200) {
      throw new Error('Server is not responding');
    }
    console.log('✅ Server is running');
    
    // Step 2: Run the complete survey fix
    console.log('\n2. Running complete survey fix...');
    const fixResponse = await makeRailwayRequest('/api/admin/fix-survey-issue', 'POST');
    
    console.log('Fix response status:', fixResponse.statusCode);
    console.log('Fix response:', fixResponse.data);
    
    if (fixResponse.statusCode === 200) {
      const results = fixResponse.data.results;
      console.log('\n📊 Fix Results:');
      console.log(`   Kiosk Patient: ${results.kioskPatient ? '✅' : '❌'}`);
      console.log(`   Dental Surveys Table: ${results.dentalSurveysTable ? '✅' : '❌'}`);
      console.log(`   Survey Test: ${results.surveyTest ? '✅' : '❌'}`);
      
      if (fixResponse.data.success) {
        console.log('\n🎉 Survey fix completed successfully!');
      } else {
        console.log('\n⚠️ Survey fix partially completed');
      }
    } else {
      console.log('\n❌ Survey fix failed');
    }
    
    // Step 3: Test survey submission
    console.log('\n3. Testing survey submission...');
    const testData = JSON.stringify({
      surveyData: {
        patient_info: {
          name: 'Auto Fix Test',
          email: 'autofix@test.com'
        },
        submitted_at: new Date().toISOString(),
        submitted_via: 'kiosk'
      }
    });
    
    const testResponse = await makeRailwayRequest('/api/surveys', 'POST', testData);
    console.log('Test response status:', testResponse.statusCode);
    console.log('Test response:', testResponse.data);
    
    if (testResponse.statusCode === 200) {
      console.log('\n🎉 Survey submission is now working!');
      console.log('✅ The Flutter app should now be able to submit surveys successfully');
    } else {
      console.log('\n❌ Survey submission still failing');
      console.log('📋 Manual intervention may still be needed');
    }
    
  } catch (error) {
    console.error('❌ Automated fix failed:', error.message);
    console.log('\n📋 Manual steps needed:');
    console.log('1. Access Railway database via dashboard');
    console.log('2. Run the kiosk patient creation SQL');
    console.log('3. Test survey submission');
  }
}

// Run the automated fix
autoFixSurvey()
  .then(() => {
    console.log('\n✅ Automated fix process completed');
  })
  .catch(error => {
    console.error('\n❌ Automated fix process failed:', error);
  }); 