const https = require('https');

// Create vincent1@gmail.com account
async function createVincentAccount() {
  console.log('🔧 Creating vincent1@gmail.com account...');
  
  try {
    const registrationData = JSON.stringify({
      firstName: 'Vincent',
      lastName: 'Test',
      email: 'vincent1@gmail.com',
      phone: '09123456789',
      password: 'password123',
      dateOfBirth: '1990-01-01',
      address: 'Test Address',
      emergencyContact: 'Emergency Contact',
      emergencyPhone: '09123456789',
      classification: 'Others',
      otherClassification: 'Test User',
      serialNumber: 'VIN001',
      unitAssignment: 'Test Unit'
    });
    
    const response = await makeRequest('/api/auth/register', 'POST', registrationData);
    console.log('Registration status:', response.statusCode);
    console.log('Registration response:', response.data);
    
    if (response.statusCode === 201 || response.statusCode === 200) {
      console.log('\n✅ vincent1@gmail.com account created successfully!');
      console.log('📋 You can now use:');
      console.log('   Email: vincent1@gmail.com');
      console.log('   Password: password123');
      
      // Test login immediately
      console.log('\n🧪 Testing login with new account...');
      const loginData = JSON.stringify({
        email: 'vincent1@gmail.com',
        password: 'password123'
      });
      
      const loginResponse = await makeRequest('/api/auth/login', 'POST', loginData);
      if (loginResponse.statusCode === 200) {
        console.log('✅ Login successful! Account is ready to use');
      } else {
        console.log('❌ Login failed after creation');
      }
      
    } else {
      console.log('\n❌ Failed to create account');
      console.log('📋 You may need to use the Flutter app to register');
    }
    
  } catch (error) {
    console.error('❌ Error creating account:', error.message);
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
        'Content-Type': 'application/json'
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

// Run the account creation
createVincentAccount()
  .then(() => {
    console.log('\n✅ Account creation process completed');
  })
  .catch(error => {
    console.error('\n❌ Account creation failed:', error);
  }); 