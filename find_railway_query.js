const https = require('https');

// Function to check Railway project structure
async function checkRailwayProject() {
  console.log('🔍 Checking Railway project structure...');
  
  try {
    // Try to get project info (this might not work due to auth)
    const response = await makeRequest('/health');
    console.log('Server health:', response.statusCode === 200 ? '✅ OK' : '❌ Failed');
    
    console.log('\n📋 RAILWAY NAVIGATION HELP:');
    console.log('=====================================');
    console.log('1. Go to: https://railway.app');
    console.log('2. Sign in to your account');
    console.log('3. Look for project: "AFP dental app" or "afp-dental-app-production"');
    console.log('4. Click on the project');
    console.log('');
    console.log('5. You should see TWO services:');
    console.log('   - Node.js service (your backend)');
    console.log('   - PostgreSQL service (your database)');
    console.log('');
    console.log('6. Click on the PostgreSQL service');
    console.log('');
    console.log('7. Look for these options:');
    console.log('   - "Connect" button');
    console.log('   - "Query" tab');
    console.log('   - "SQL Editor" tab');
    console.log('   - "Database" tab');
    console.log('');
    console.log('8. If you see "Connect":');
    console.log('   - Click "Connect"');
    console.log('   - Then look for "Query" or "SQL Editor"');
    console.log('');
    console.log('9. If you don\'t see query options:');
    console.log('   - Look for "Variables" tab');
    console.log('   - Look for "Settings" tab');
    console.log('   - The query interface might not be available on free plan');
    console.log('');
    console.log('🔧 ALTERNATIVE SOLUTION:');
    console.log('If you can\'t find the query interface:');
    console.log('1. Look for database connection details');
    console.log('2. Use a tool like pgAdmin or DBeaver');
    console.log('3. Connect to your Railway database');
    console.log('4. Run the SQL command there');
    
  } catch (error) {
    console.error('❌ Error checking project:', error.message);
  }
}

function makeRequest(path, method = 'GET') {
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

    req.end();
  });
}

// Run the check
checkRailwayProject()
  .then(() => {
    console.log('\n✅ Railway navigation guide completed');
    console.log('\n📝 NEXT STEPS:');
    console.log('1. Follow the navigation guide above');
    console.log('2. Find the query interface in Railway');
    console.log('3. Run the SQL command to create kiosk patient');
    console.log('4. Test survey submission in your Flutter app');
  })
  .catch(error => {
    console.error('\n❌ Railway navigation check failed:', error);
  }); 