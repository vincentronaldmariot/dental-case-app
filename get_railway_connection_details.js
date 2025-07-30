const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

async function getRailwayConnectionDetails() {
  try {
    console.log('🔍 Getting Railway database connection details...');
    
    // Get the DATABASE_URL from Railway
    const { stdout } = await execAsync('railway variables');
    
    console.log('📋 Railway Variables:');
    console.log(stdout);
    
    console.log('\n🔧 For pgAdmin connection, you need:');
    console.log('1. Host: ballast.proxy.rlwy.net');
    console.log('2. Port: 27199');
    console.log('3. Database: railway');
    console.log('4. Username: postgres');
    console.log('5. Password: glfJbkmkHHAAlKQqFzNtkMQjXO PjJthr');
    
    console.log('\n📋 pgAdmin Connection Steps:');
    console.log('1. Open pgAdmin');
    console.log('2. Right-click on "Servers" → "Register" → "Server"');
    console.log('3. In the "General" tab:');
    console.log('   - Name: Railway Dental App');
    console.log('4. In the "Connection" tab:');
    console.log('   - Host: ballast.proxy.rlwy.net');
    console.log('   - Port: 27199');
    console.log('   - Database: railway');
    console.log('   - Username: postgres');
    console.log('   - Password: glfJbkmkHHAAlKQqFzNtkMQjXO PjJthr');
    console.log('5. In the "SSL" tab:');
    console.log('   - SSL Mode: Require');
    console.log('   - SSL Compression: No');
    console.log('6. Click "Save"');
    
    console.log('\n🔧 Once connected, run these SQL commands:');
    console.log('ALTER TABLE dental_surveys ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;');
    console.log('ALTER TABLE dental_surveys ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.log('\n🔧 Manual connection details:');
    console.log('Host: ballast.proxy.rlwy.net');
    console.log('Port: 27199');
    console.log('Database: railway');
    console.log('Username: postgres');
    console.log('Password: glfJbkmkHHAAlKQqFzNtkMQjXO PjJthr');
  }
}

getRailwayConnectionDetails(); 