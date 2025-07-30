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

// Deploy the survey fix
async function deploySurveyFix() {
  try {
    console.log('🚀 Deploying survey fix to Railway...');
    
    // Step 1: Test the current survey endpoint
    console.log('\n1. Testing current survey endpoint...');
    const testData = JSON.stringify({
      surveyData: {
        patient_info: {
          name: 'Test Fix',
          email: 'test@fix.com'
        },
        submitted_at: new Date().toISOString(),
        submitted_via: 'kiosk'
      }
    });
    
    const testResult = await makeRailwayRequest('/api/surveys', 'POST', testData);
    console.log('Test result:', testResult);
    
    if (testResult.statusCode === 200) {
      console.log('✅ Survey submission is already working!');
      return;
    }
    
    // Step 2: Try to create the kiosk patient via a special endpoint
    console.log('\n2. Creating kiosk patient...');
    const kioskPatientData = JSON.stringify({
      id: '00000000-0000-0000-0000-000000000000',
      firstName: 'Kiosk',
      lastName: 'User',
      email: 'kiosk@dental.app',
      phone: '00000000000',
      password: 'kiosk_password',
      dateOfBirth: '2000-01-01',
      address: 'Kiosk Location',
      emergencyContact: 'Kiosk Emergency',
      emergencyPhone: '00000000000'
    });
    
    try {
      const createPatientResult = await makeRailwayRequest('/api/admin/patients/kiosk', 'POST', kioskPatientData);
      console.log('Create patient result:', createPatientResult);
    } catch (error) {
      console.log('Could not create kiosk patient via API, will need manual fix');
    }
    
    // Step 3: Test survey submission again
    console.log('\n3. Testing survey submission after fix...');
    const finalTestResult = await makeRailwayRequest('/api/surveys', 'POST', testData);
    console.log('Final test result:', finalTestResult);
    
    if (finalTestResult.statusCode === 200) {
      console.log('✅ Survey fix deployed successfully!');
    } else {
      console.log('❌ Survey fix needs manual intervention');
      console.log('Manual steps needed:');
      console.log('1. Access Railway database');
      console.log('2. Create kiosk patient with ID: 00000000-0000-0000-0000-000000000000');
      console.log('3. Ensure dental_surveys table exists with proper constraints');
    }
    
  } catch (error) {
    console.error('❌ Deployment failed:', error);
  }
}

// Run the deployment
deploySurveyFix()
  .then(() => {
    console.log('\n✅ Deployment process completed');
  })
  .catch(error => {
    console.error('\n❌ Deployment process failed:', error);
  }); 