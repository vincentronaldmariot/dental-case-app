const http = require('http');

function makeRequest(method, path, data, headers = {}) {
  return new Promise((resolve, reject) => {
    const postData = data ? JSON.stringify(data) : '';
    
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...headers
      }
    };

    if (postData) {
      options.headers['Content-Length'] = Buffer.byteLength(postData);
    }

    const req = http.request(options, (res) => {
      let responseData = '';
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: responseData
        });
      });
    });

    req.on('error', (e) => {
      reject(e);
    });

    if (postData) {
      req.write(postData);
    }
    req.end();
  });
}

async function testSpecificLogin() {
  console.log('Testing specific login credentials...\n');

  // Test with existing patient from database
  const testCases = [
    { email: 'john.doe@test.com', password: 'password123', description: 'John Doe with correct password' },
    { email: 'jane.smith@test.com', password: 'password123', description: 'Jane Smith with correct password' },
    { email: 'vip.person@test.com', password: 'password123', description: 'VIP Person with correct password' },
    { email: 'viperson1@gmail.com', password: 'password123', description: 'VIP Person 1 with correct password' }
  ];

  for (const testCase of testCases) {
    console.log(`\n--- ${testCase.description} ---`);
    
    try {
      const response = await makeRequest(
        'POST',
        '/api/auth/login',
        {
          email: testCase.email,
          password: testCase.password
        }
      );
      
      if (response.statusCode === 200) {
        const data = JSON.parse(response.body);
        console.log('✅ LOGIN SUCCESSFUL');
        console.log(`📊 Patient ID: ${data.patient.id}`);
        console.log(`👤 Name: ${data.patient.firstName} ${data.patient.lastName}`);
        console.log(`🔑 Token: ${data.token.substring(0, 50)}...`);
      } else {
        console.log(`Status: ${response.statusCode}`);
        console.log(`Response: ${response.body}`);
        console.log('❌ LOGIN FAILED');
      }
    } catch (error) {
      console.log(`❌ Error: ${error.message}`);
      console.log(`Error details: ${error}`);
    }
  }
}

testSpecificLogin(); 