const { exec } = require('child_process');
const fs = require('fs');

console.log('🔧 Railway Database Fix Script\n');

console.log('📋 PREREQUISITES:');
console.log('1. Install Railway CLI: npm install -g @railway/cli');
console.log('2. Login to Railway: railway login');
console.log('3. Link your project: railway link');
console.log('\n');

// Check if Railway CLI is installed
exec('railway --version', (error, stdout, stderr) => {
  if (error) {
    console.log('❌ Railway CLI not found. Please install it first:');
    console.log('   npm install -g @railway/cli');
    console.log('   railway login');
    console.log('   railway link');
    return;
  }
  
  console.log('✅ Railway CLI found:', stdout.trim());
  
  // Create SQL file
  const sqlCommands = `
-- Add missing columns to emergency_records table
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'reported';
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS priority VARCHAR(50) DEFAULT 'standard';
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS handled_by VARCHAR(100);
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS resolution TEXT;
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS follow_up_required TEXT;
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP;
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS emergency_contact VARCHAR(100);
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS notes TEXT;

-- Update existing records with default values
UPDATE emergency_records SET status = 'reported' WHERE status IS NULL;
UPDATE emergency_records SET priority = 'standard' WHERE priority IS NULL;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_emergency_records_status ON emergency_records(status);
CREATE INDEX IF NOT EXISTS idx_emergency_records_priority ON emergency_records(priority);
CREATE INDEX IF NOT EXISTS idx_emergency_records_patient_id ON emergency_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_emergency_records_emergency_date ON emergency_records(emergency_date);
`;

  fs.writeFileSync('emergency_fix.sql', sqlCommands);
  console.log('✅ Created emergency_fix.sql file');
  
  console.log('\n🚀 RUNNING DATABASE FIX...');
  console.log('Executing: railway run -- psql -f emergency_fix.sql');
  
  exec('railway run -- psql -f emergency_fix.sql', (error, stdout, stderr) => {
    if (error) {
      console.log('❌ Error executing SQL:', error.message);
      console.log('\n📋 MANUAL STEPS REQUIRED:');
      console.log('1. Go to Railway Dashboard');
      console.log('2. Find your PostgreSQL service');
      console.log('3. Look for "Connect" or "Variables" tab');
      console.log('4. Copy the DATABASE_URL or connection details');
      console.log('5. Use a database client like DBeaver or pgAdmin');
      return;
    }
    
    console.log('✅ SQL executed successfully!');
    console.log('Output:', stdout);
    
    // Clean up
    fs.unlinkSync('emergency_fix.sql');
    console.log('✅ Cleaned up temporary files');
    
    console.log('\n🎉 DATABASE FIX COMPLETED!');
    console.log('Now restart your Flutter app and test the admin emergencies tab.');
  });
}); 