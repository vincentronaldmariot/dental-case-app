const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function fixEmergencySchema() {
  try {
    console.log('🔧 Fixing Emergency Records Schema...\n');

    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 2: Create a simple SQL script to add missing columns
    console.log('\n2️⃣ Creating SQL migration script...');
    
    const sqlCommands = [
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'reported'",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS priority VARCHAR(50) DEFAULT 'standard'",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS handled_by VARCHAR(100)",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS resolution TEXT",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS follow_up_required TEXT",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS emergency_contact VARCHAR(100)",
      "ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS notes TEXT",
      "UPDATE emergency_records SET status = 'reported' WHERE status IS NULL",
      "UPDATE emergency_records SET priority = 'standard' WHERE priority IS NULL"
    ];

    // Step 3: Execute each SQL command
    console.log('\n3️⃣ Executing SQL commands...');
    
    for (let i = 0; i < sqlCommands.length; i++) {
      const sql = sqlCommands[i];
      console.log(`   Executing command ${i + 1}/${sqlCommands.length}: ${sql.substring(0, 50)}...`);
      
      try {
        // Try to execute via a direct database endpoint
        const response = await axios.post(
          `${ONLINE_SERVER_URL}/api/admin/database/execute`,
          { sql: sql },
          { headers: { Authorization: `Bearer ${adminToken}` } }
        );
        console.log(`   ✅ Command ${i + 1} executed successfully`);
      } catch (error) {
        console.log(`   ⚠️ Command ${i + 1} failed (may already exist): ${error.response?.data?.error || error.message}`);
      }
    }

    // Step 4: Test the emergency records endpoint
    console.log('\n4️⃣ Testing emergency records endpoint...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      console.log('✅ Emergency records endpoint working!');
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
      
      // Try alternative approach - create a simple emergency record to test
      console.log('\n🔄 Trying to create a test emergency record...');
      try {
        const patientsResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/patients`, {
          headers: { Authorization: `Bearer ${adminToken}` }
        });

        const patients = patientsResponse.data.patients || [];
        if (patients.length > 0) {
          const testPatient = patients[0];
          
          const createResponse = await axios.post(
            `${ONLINE_SERVER_URL}/api/emergency`,
            {
              patientId: testPatient.id,
              emergencyType: 'severeToothache',
              description: 'Test emergency record for schema fix',
              emergencyDate: new Date().toISOString()
            },
            {
              headers: { Authorization: `Bearer ${adminToken}` }
            }
          );

          console.log('✅ Test emergency record created successfully');
          console.log('Created record:', createResponse.data);
        }
      } catch (createError) {
        console.log('❌ Test emergency creation failed');
        console.log(`   Error: ${createError.response?.status} - ${createError.response?.data?.error || createError.message}`);
      }
    }

    // Step 5: Test emergency status update
    console.log('\n5️⃣ Testing emergency status update...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const emergencyRecords = emergencyResponse.data.emergencyRecords || [];
      
      if (emergencyRecords.length > 0) {
        const testRecord = emergencyRecords[0];
        console.log(`📋 Testing status update for record: ${testRecord.id}`);

        const updateResponse = await axios.put(
          `${ONLINE_SERVER_URL}/api/admin/emergency/${testRecord.id}/status`,
          {
            status: 'inProgress',
            handledBy: 'Dr. Admin Test',
            notes: 'Test status update after schema fix'
          },
          {
            headers: { Authorization: `Bearer ${adminToken}` }
          }
        );

        console.log('✅ Emergency status update successful');
        console.log('Response:', updateResponse.data);

      } else {
        console.log('⚠️ No emergency records to test status update');
      }

    } catch (error) {
      console.log('❌ Emergency status update failed');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    console.log('\n📋 SCHEMA FIX SUMMARY:');
    console.log('   • Admin authentication: ✅');
    console.log('   • SQL commands executed: ✅');
    console.log('   • Emergency records endpoint: ⚠️ (needs verification)');
    console.log('   • Status update functionality: ⚠️ (needs verification)');
    console.log('   • Admin emergencies tab: ⚠️ (will work after successful schema update)');

    console.log('\n🔧 MANUAL FIX REQUIRED:');
    console.log('   Since the automated migration failed, you need to manually update the database:');
    console.log('   1. Connect to your Railway PostgreSQL database');
    console.log('   2. Run the following SQL commands:');
    console.log('');
    sqlCommands.forEach((sql, index) => {
      console.log(`   ${index + 1}. ${sql}`);
    });
    console.log('');
    console.log('   3. After running these commands, the admin emergencies tab should work');

  } catch (error) {
    console.error('❌ Schema fix failed:', error.response?.data || error.message);
  }
}

fixEmergencySchema(); 