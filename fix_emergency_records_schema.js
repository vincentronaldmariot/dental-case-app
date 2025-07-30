const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function fixEmergencyRecordsSchema() {
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

    // Step 2: Add missing columns to emergency_records table
    console.log('\n2️⃣ Adding missing columns to emergency_records table...');
    
    const missingColumns = [
      'status VARCHAR(50) DEFAULT \'reported\'',
      'priority VARCHAR(50) DEFAULT \'standard\'',
      'handled_by VARCHAR(100)',
      'resolution TEXT',
      'follow_up_required TEXT',
      'resolved_at TIMESTAMP',
      'emergency_contact VARCHAR(100)',
      'notes TEXT'
    ];

    for (const column of missingColumns) {
      try {
        const columnName = column.split(' ')[0];
        console.log(`   Adding column: ${columnName}`);
        
        const alterResponse = await axios.post(
          `${ONLINE_SERVER_URL}/api/admin/fix-database`,
          {
            action: 'add_column',
            table: 'emergency_records',
            column: column,
            columnName: columnName
          },
          {
            headers: { Authorization: `Bearer ${adminToken}` }
          }
        );

        console.log(`   ✅ Added column: ${columnName}`);

      } catch (error) {
        if (error.response?.status === 400 && error.response?.data?.error?.includes('already exists')) {
          console.log(`   ⚠️ Column already exists: ${column.split(' ')[0]}`);
        } else {
          console.log(`   ❌ Failed to add column: ${column.split(' ')[0]}`);
          console.log(`      Error: ${error.response?.data?.error || error.message}`);
        }
      }
    }

    // Step 3: Test the emergency records endpoint after schema fix
    console.log('\n3️⃣ Testing emergency records endpoint after schema fix...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      console.log('✅ Emergency records endpoint working after schema fix');
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

    // Step 4: Test emergency status update
    console.log('\n4️⃣ Testing emergency status update...');
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
    console.log('   • Schema migration: ⚠️ (needs deployment)');
    console.log('   • Emergency records endpoint: ⚠️ (needs verification)');
    console.log('   • Status update functionality: ⚠️ (needs verification)');
    console.log('   • Admin emergencies tab: ⚠️ (will work after deployment)');

  } catch (error) {
    console.error('❌ Schema fix failed:', error.response?.data || error.message);
  }
}

fixEmergencyRecordsSchema(); 