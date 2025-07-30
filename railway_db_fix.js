const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

async function fixDatabaseWithRailwayCLI() {
  try {
    console.log('🔍 Checking Railway CLI installation...');
    
    // Check if Railway CLI is installed
    try {
      await execAsync('railway --version');
      console.log('✅ Railway CLI is installed');
    } catch (error) {
      console.log('❌ Railway CLI not found. Installing...');
      await execAsync('npm install -g @railway/cli');
      console.log('✅ Railway CLI installed');
    }
    
    console.log('🔍 Logging into Railway...');
    // Note: This will require user interaction
    console.log('📋 Please run this command manually:');
    console.log('   railway login');
    console.log('   railway link');
    console.log('   railway connect');
    
    console.log('\n🔧 Then run this SQL command:');
    console.log('   ALTER TABLE dental_surveys ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;');
    console.log('   ALTER TABLE dental_surveys ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

fixDatabaseWithRailwayCLI(); 