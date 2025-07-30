const axios = require('axios');
const fs = require('fs');
const path = require('path');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function runEmergencyMigration() {
  try {
    console.log('🔧 Running Emergency Records Migration...\n');

    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 2: Read the migration SQL file
    console.log('\n2️⃣ Reading migration SQL file...');
    const migrationPath = path.join(__dirname, 'backend', 'migrations', 'add_emergency_columns.sql');
    
    if (!fs.existsSync(migrationPath)) {
      console.log('❌ Migration file not found');
      console.log('Creating migration file...');
      
      const migrationSQL = `-- Migration: Add missing columns to emergency_records table
-- This fixes the admin emergencies tab by adding the required columns

-- Add status column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'reported';

-- Add priority column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS priority VARCHAR(50) DEFAULT 'standard';

-- Add handled_by column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS handled_by VARCHAR(100);

-- Add resolution column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS resolution TEXT;

-- Add follow_up_required column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS follow_up_required TEXT;

-- Add resolved_at column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP;

-- Add emergency_contact column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS emergency_contact VARCHAR(100);

-- Add notes column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Update existing records to have proper default values
UPDATE emergency_records 
SET status = 'reported' 
WHERE status IS NULL;

UPDATE emergency_records 
SET priority = 'standard' 
WHERE priority IS NULL;`;

      // Ensure migrations directory exists
      const migrationsDir = path.dirname(migrationPath);
      if (!fs.existsSync(migrationsDir)) {
        fs.mkdirSync(migrationsDir, { recursive: true });
      }
      
      fs.writeFileSync(migrationPath, migrationSQL);
      console.log('✅ Migration file created');
    }

    const migrationSQL = fs.readFileSync(migrationPath, 'utf8');
    console.log('✅ Migration SQL loaded');

    // Step 3: Execute the migration
    console.log('\n3️⃣ Executing migration...');
    try {
      const migrationResponse = await axios.post(
        `${ONLINE_SERVER_URL}/api/admin/execute-migration`,
        {
          sql: migrationSQL,
          description: 'Add missing columns to emergency_records table'
        },
        {
          headers: { Authorization: `Bearer ${adminToken}` }
        }
      );

      console.log('✅ Migration executed successfully');
      console.log('Response:', migrationResponse.data);

    } catch (error) {
      console.log('❌ Migration execution failed');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
      
      // Try alternative approach - execute SQL directly
      console.log('\n🔄 Trying alternative migration approach...');
      try {
        const sqlCommands = migrationSQL.split(';').filter(cmd => cmd.trim());
        
        for (const sqlCommand of sqlCommands) {
          if (sqlCommand.trim()) {
            console.log(`   Executing: ${sqlCommand.substring(0, 50)}...`);
            
            const sqlResponse = await axios.post(
              `${ONLINE_SERVER_URL}/api/admin/execute-sql`,
              {
                sql: sqlCommand.trim()
              },
              {
                headers: { Authorization: `Bearer ${adminToken}` }
              }
            );

            console.log(`   ✅ SQL command executed`);
          }
        }

      } catch (sqlError) {
        console.log('❌ Alternative migration approach failed');
        console.log(`   Error: ${sqlError.response?.status} - ${sqlError.response?.data?.error || sqlError.message}`);
      }
    }

    // Step 4: Test the emergency records endpoint after migration
    console.log('\n4️⃣ Testing emergency records endpoint after migration...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      console.log('✅ Emergency records endpoint working after migration');
      console.log(`📊 Found ${emergencyResponse.data.emergencyRecords?.length || 0} emergency records`);

      if (emergencyResponse.data.emergencyRecords?.length > 0) {
        console.log('\n📋 Sample emergency record:');
        const sampleRecord = emergencyResponse.data.emergencyRecords[0];
        console.log(`   • ID: ${sampleRecord.id}`);
        console.log(`   • Patient: ${sampleRecord.patientName}`);
        console.log(`   • Type: ${sampleRecord.emergencyType}`);
        console.log(`   • Status: ${sampleRecord.status}`);
        console.log(`   • Priority: ${sampleRecord.priority}`);
      }

    } catch (error) {
      console.log('❌ Emergency records endpoint still failing');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    console.log('\n📋 MIGRATION SUMMARY:');
    console.log('   • Admin authentication: ✅');
    console.log('   • Migration file: ✅');
    console.log('   • Migration execution: ⚠️ (needs verification)');
    console.log('   • Emergency records endpoint: ⚠️ (needs verification)');
    console.log('   • Admin emergencies tab: ⚠️ (will work after successful migration)');

  } catch (error) {
    console.error('❌ Migration failed:', error.response?.data || error.message);
  }
}

runEmergencyMigration(); 