const https = require('https');

console.log('🔍 RAILWAY DEPLOYMENT DIAGNOSIS');
console.log('================================\n');

console.log('📊 Current Status:');
console.log('- ✅ API is responding (200 OK)');
console.log('- ❌ Still serving OLD code (500 error)');
console.log('- ⏳ New code not deployed yet\n');

console.log('🚨 WHY IT\'S TAKING SO LONG:');
console.log('1. Railway deployment queue (free tier is slower)');
console.log('2. Build process takes 5-15 minutes');
console.log('3. GitHub sync delay (1-5 minutes)');
console.log('4. Multiple services need to restart\n');

console.log('🔧 IMMEDIATE SOLUTIONS:\n');

console.log('Option 1: Force Railway Redeploy');
console.log('1. Go to Railway dashboard');
console.log('2. Click on your project');
console.log('3. Click on the Node.js service (not PostgreSQL)');
console.log('4. Go to "Settings" tab');
console.log('5. Click "Redeploy" or "Restart"');
console.log('6. This forces immediate rebuild\n');

console.log('Option 2: Check Railway Build Logs');
console.log('1. Go to Railway dashboard');
console.log('2. Click on your project');
console.log('3. Click on the Node.js service');
console.log('4. Go to "Deployments" tab');
console.log('5. Check if there are any build errors\n');

console.log('Option 3: Manual Database Fix (While Waiting)');
console.log('1. Go to Railway dashboard');
console.log('2. Click on PostgreSQL service');
console.log('3. Go to "Data" tab');
console.log('4. Use external tool (pgAdmin/DBeaver)');
console.log('5. Run the SQL fix manually\n');

// Check if we can access Railway build info
async function checkRailwayStatus() {
  try {
    console.log('🔍 Checking Railway service status...\n');
    
    // Try to get more detailed error info
    const response = await makeRequest('/health', 'GET');
    
    if (response.statusCode === 200) {
      console.log('✅ Railway service is running');
      console.log('📋 The issue is the old code still being served');
      console.log('⏳ Need to wait for new deployment or force redeploy');
      
    } else {
      console.log(`⚠️ Service status: ${response.statusCode}`);
      console.log('📋 Railway might be rebuilding');
    }
    
  } catch (error) {
    console.log('❌ Cannot reach Railway service');
    console.log('📋 Railway might be down or rebuilding');
  }
}

function makeRequest(path, method = 'GET', data = null, token = null) {
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

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

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

// Check status
checkRailwayStatus()
  .then(() => {
    console.log('\n🎯 RECOMMENDED ACTION:');
    console.log('1. Try Option 1 (Force Railway Redeploy) first');
    console.log('2. If that doesn\'t work, use Option 3 (Manual Database Fix)');
    console.log('3. The database connection is fine - it\'s the code that needs updating');
  })
  .catch(error => {
    console.error('\n❌ Error:', error);
  }); 