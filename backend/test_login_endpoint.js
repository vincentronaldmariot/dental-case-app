const http = require('http');

// Test patient login endpoint
function testPatientLogin() {
  const postData = JSON.stringify({
    email: 'test@example.com',
    password: 'password123'
  });

  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(postData)
    }
  };

  const req = http.request(options, (res) => {
    console.log(`Status: ${res.statusCode}`);
    console.log(`Headers: ${JSON.stringify(res.headers)}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('Response:', data);
      try {
        const jsonResponse = JSON.parse(data);
        console.log('Parsed response:', jsonResponse);
      } catch (e) {
        console.log('Could not parse JSON response');
      }
    });
  });

  req.on('error', (e) => {
    console.error(`Problem with request: ${e.message}`);
  });

  req.write(postData);
  req.end();
}

// Test with different credentials
function testMultipleLogins() {
  const testCases = [
    { email: 'test@example.com', password: 'password123' },
    { email: 'john.doe@example.com', password: 'password123' },
    { email: 'vincent@gmail.com', password: 'password123' },
    { email: 'mariot@gmail.com', password: 'password123' }
  ];

  testCases.forEach((testCase, index) => {
    console.log(`\n--- Test Case ${index + 1}: ${testCase.email} ---`);
    
    const postData = JSON.stringify(testCase);
    
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = http.request(options, (res) => {
      console.log(`Status: ${res.statusCode}`);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log('Response:', data);
      });
    });

    req.on('error', (e) => {
      console.error(`Error: ${e.message}`);
    });

    req.write(postData);
    req.end();
    
    // Add delay between requests
    setTimeout(() => {}, 1000);
  });
}

console.log('Testing patient login endpoint...');
testMultipleLogins(); 