const http = require('http');

// Test exactly what Flutter is sending
function testFlutterLogin() {
  const testCases = [
    { email: 'vincent@gmail.com', password: 'flarelight' },
    { email: 'vincent@gmail.com', password: 'password123' },
  ];

  testCases.forEach((testCase, index) => {
    console.log(`\n--- Flutter-style Test ${index + 1}: ${testCase.email} ---`);
    
    const postData = JSON.stringify(testCase);
    
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/login',  // This is what Flutter is calling
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    console.log('Request URL:', `http://localhost:3000${options.path}`);
    console.log('Request Headers:', options.headers);
    console.log('Request Body:', postData);

    const req = http.request(options, (res) => {
      console.log(`\nResponse Status: ${res.statusCode}`);
      console.log('Response Headers:', res.headers);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log('Response Body:', data);
        if (res.statusCode === 200) {
          console.log('✅ LOGIN SUCCESSFUL!');
        } else {
          console.log('❌ LOGIN FAILED');
        }
      });
    });

    req.on('error', (e) => {
      console.error(`Request Error: ${e.message}`);
    });

    req.write(postData);
    req.end();
    
    // Add delay between requests
    setTimeout(() => {}, 2000);
  });
}

console.log('Testing Flutter-style login requests...');
testFlutterLogin(); 