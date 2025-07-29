const https = require('https');

async function testOnlineServer() {
  console.log('Testing online server login...');
  
  const data = JSON.stringify({
    email: 'viperson1@gmail.com',
    password: 'password123'
  });

  const options = {
    hostname: 'afp-dental-app-production.up.railway.app',
    port: 443,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        console.log(`Status: ${res.statusCode}`);
        console.log(`Response: ${responseData}`);
        
        if (res.statusCode === 200) {
          console.log('✅ Online server login successful!');
        } else {
          console.log('❌ Online server login failed');
        }
        resolve();
      });
    });

    req.on('error', (error) => {
      console.error('❌ Request error:', error);
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

testOnlineServer().catch(console.error);