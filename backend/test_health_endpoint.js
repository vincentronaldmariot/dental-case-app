const http = require('http');

// Test health endpoint
function testHealthEndpoint() {
  console.log('Testing health endpoint...');
  
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/health',
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json'
    }
  };

  console.log('Request URL:', `http://localhost:3000${options.path}`);
  console.log('Request Headers:', options.headers);

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
        console.log('✅ Health endpoint is working!');
      } else {
        console.log('❌ Health endpoint failed');
      }
    });
  });

  req.on('error', (e) => {
    console.error(`Request Error: ${e.message}`);
  });

  req.end();
}

// Test auth endpoint
function testAuthEndpoint() {
  console.log('\nTesting auth endpoint...');
  
  const postData = JSON.stringify({
    email: 'vincent@gmail.com',
    password: 'flarelight'
  });
  
  const options = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/login',
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
        console.log('✅ Auth endpoint is working!');
      } else {
        console.log('❌ Auth endpoint failed');
      }
    });
  });

  req.on('error', (e) => {
    console.error(`Request Error: ${e.message}`);
  });

  req.write(postData);
  req.end();
}

testHealthEndpoint();
setTimeout(testAuthEndpoint, 1000); 