const http = require('http');

// Test the specific login that's failing
function testSpecificLogin() {
  const testCases = [
    { email: 'vincent@gmail.com', password: 'flarelight' },  // What user is trying
    { email: 'vincent@gmail.com', password: 'password123' }, // What it should be
    { email: 'vincent@gmail.com', password: 'password' },    // Alternative
  ];

  testCases.forEach((testCase, index) => {
    console.log(`\n--- Test ${index + 1}: ${testCase.email} with "${testCase.password}" ---`);
    
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
        if (res.statusCode === 200) {
          console.log('✅ LOGIN SUCCESSFUL!');
        } else {
          console.log('❌ LOGIN FAILED');
        }
      });
    });

    req.on('error', (e) => {
      console.error(`Error: ${e.message}`);
    });

    req.write(postData);
    req.end();
    
    // Add delay between requests
    setTimeout(() => {}, 2000);
  });
}

console.log('Testing specific login credentials...');
testSpecificLogin(); 