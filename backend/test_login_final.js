const http = require('http');

// Test both login and registration
function testLoginAndRegistration() {
  console.log('🧪 Testing Login and Registration...\n');
  
  // Test 1: Login with correct credentials
  console.log('--- Test 1: Login with correct credentials ---');
  const loginData = JSON.stringify({
    email: 'vincent@gmail.com',
    password: 'password123'
  });
  
  const loginOptions = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/auth/login',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Content-Length': Buffer.byteLength(loginData)
    }
  };

  const loginReq = http.request(loginOptions, (res) => {
    console.log(`Login Status: ${res.statusCode}`);
    
    let data = '';
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log('Login Response:', data);
      if (res.statusCode === 200) {
        console.log('✅ LOGIN SUCCESSFUL!\n');
      } else {
        console.log('❌ LOGIN FAILED\n');
      }
      
      // Test 2: Registration with correct classification
      setTimeout(() => {
        console.log('--- Test 2: Registration with correct classification ---');
        const regData = JSON.stringify({
          firstName: 'Test',
          lastName: 'User',
          email: 'testuser123@gmail.com',
          password: 'password123',
          phone: '1234567890',
          dateOfBirth: '1990-01-01',
          address: 'Test Address',
          emergencyContact: 'Emergency Contact',
          emergencyPhone: '0987654321',
          medicalHistory: 'None',
          allergies: 'None',
          serialNumber: 'TEST123',
          unitAssignment: 'Test Unit',
          classification: 'Others',
          otherClassification: 'Test Classification'
        });
        
        const regOptions = {
          hostname: 'localhost',
          port: 3000,
          path: '/api/auth/register',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Content-Length': Buffer.byteLength(regData)
          }
        };

        const regReq = http.request(regOptions, (res) => {
          console.log(`Registration Status: ${res.statusCode}`);
          
          let data = '';
          res.on('data', (chunk) => {
            data += chunk;
          });
          
          res.on('end', () => {
            console.log('Registration Response:', data);
            if (res.statusCode === 201) {
              console.log('✅ REGISTRATION SUCCESSFUL!\n');
            } else {
              console.log('❌ REGISTRATION FAILED\n');
            }
            
            console.log('🎉 Testing completed!');
          });
        });

        regReq.on('error', (e) => {
          console.error(`Registration Error: ${e.message}`);
        });

        regReq.write(regData);
        regReq.end();
      }, 1000);
    });
  });

  loginReq.on('error', (e) => {
    console.error(`Login Error: ${e.message}`);
  });

  loginReq.write(loginData);
  loginReq.end();
}

testLoginAndRegistration(); 