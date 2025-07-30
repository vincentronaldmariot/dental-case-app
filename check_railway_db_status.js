const https = require('https');

console.log('🔍 CHECKING RAILWAY DATABASE STATUS');
console.log('===================================\n');

console.log('📊 Testing current connection details...\n');

async function checkDatabaseStatus() {
  try {
    console.log('🔍 Testing hostname: ballast.proxy.rlwy.net');
    console.log('🔍 Testing port: 5432');
    console.log('🔍 Testing database: railway');
    console.log('🔍 Testing username: postgres\n');

    // Test if we can reach the host
    const testConnection = () => {
      return new Promise((resolve, reject) => {
        const req = https.request({
          hostname: 'ballast.proxy.rlwy.net',
          port: 443,
          path: '/',
          method: 'GET',
          timeout: 10000
        }, (res) => {
          resolve({ statusCode: res.statusCode, headers: res.headers });
        });

        req.on('error', (error) => {
          reject(error);
        });

        req.on('timeout', () => {
          req.destroy();
          reject(new Error('Connection timeout'));
        });

        req.end();
      });
    };

    const result = await testConnection();
    console.log('✅ Host is reachable!');
    console.log('📋 Status:', result.statusCode);
    console.log('📋 This suggests the hostname is correct\n');

    console.log('🔧 POSSIBLE SOLUTIONS:\n');

    console.log('Option 1: Check Railway Dashboard');
    console.log('1. Go to Railway dashboard');
    console.log('2. Click on "Postgres" service');
    console.log('3. Go to "Variables" tab');
    console.log('4. Check if DATABASE_PUBLIC_URL has changed');
    console.log('5. Copy the new connection details\n');

    console.log('Option 2: Try Different SSL Mode');
    console.log('1. Go back to "Parameters" tab in pgAdmin');
    console.log('2. Change sslmode from "prefer" to "disable"');
    console.log('3. Try connecting again\n');

    console.log('Option 3: Check Database Service Status');
    console.log('1. Go to Railway dashboard');
    console.log('2. Check if PostgreSQL service is running');
    console.log('3. If not, restart the service\n');

    console.log('Option 4: Try Alternative Connection');
    console.log('1. Go to Railway dashboard');
    console.log('2. Look for DATABASE_URL (not DATABASE_PUBLIC_URL)');
    console.log('3. Try using those connection details instead\n');

  } catch (error) {
    console.log('❌ Connection test failed:', error.message);
    console.log('\n🔧 IMMEDIATE ACTIONS:\n');
    
    console.log('1. Go to Railway dashboard');
    console.log('2. Check if PostgreSQL service is running');
    console.log('3. If it\'s stopped, restart it');
    console.log('4. Get fresh connection details from Variables tab');
  }
}

checkDatabaseStatus()
  .then(() => {
    console.log('\n🎯 RECOMMENDED ACTION:');
    console.log('Check Railway dashboard for updated connection details');
    console.log('The database might have been restarted or reconfigured');
  })
  .catch(error => {
    console.error('\n❌ Error:', error);
  }); 