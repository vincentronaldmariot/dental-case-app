const https = require('https');

// Check existing patient accounts
async function checkExistingAccounts() {
  console.log('🔍 Checking existing patient accounts...');
  
  try {
    // Try to get a list of patients (this might require admin access)
    const response = await makeRequest('/api/admin/patients', 'GET');
    console.log('Status:', response.statusCode);
    console.log('Response:', response.data);
    
    if (response.statusCode === 200) {
      console.log('\n✅ Found existing accounts');
      console.log('📋 You can use any of these accounts to test');
    } else {
      console.log('\n❌ Cannot access patient list');
      console.log('📋 You may need to create a new account');
    }
    
  } catch (error) {
    console.error('❌ Error checking accounts:', error.message);
  }
}

// Test with a common test account
async function testCommonAccounts() {
  console.log('\n🧪 Testing common test accounts...');
  
  const testAccounts = [
    { email: 'test@example.com', password: 'password123' },
    { email: 'patient@dental.app', password: 'password123' },
    { email: 'user@test.com', password: 'password123' },
    { email: 'demo@dental.app', password: 'demo123' }
  ];
  
  for (const account of testAccounts) {
    try {
      console.log(`\nTesting: ${account.email}`);
      const loginData = JSON.stringify(account);
      const response = await makeRequest('/api/auth/login', 'POST', loginData);
      
      if (response.statusCode === 200) {
        console.log(`✅ ${account.email} - LOGIN SUCCESSFUL`);
        console.log('📋 You can use this account!');
        return account;
      } else {
        console.log(`❌ ${account.email} - Login failed`);
      }
    } catch (error) {
      console.log(`❌ ${account.email} - Error: ${error.message}`);
    }
  }
  
  console.log('\n❌ No common test accounts found');
  return null;
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

// Run the checks
async function runChecks() {
  await checkExistingAccounts();
  const workingAccount = await testCommonAccounts();
  
  console.log('\n📊 Summary:');
  if (workingAccount) {
    console.log(`✅ Use this account: ${workingAccount.email}`);
    console.log(`   Password: ${workingAccount.password}`);
  } else {
    console.log('❌ No existing accounts found');
    console.log('📋 You need to create a new account');
  }
}

runChecks()
  .then(() => {
    console.log('\n✅ Account check completed');
  })
  .catch(error => {
    console.error('\n❌ Account check failed:', error);
  }); 