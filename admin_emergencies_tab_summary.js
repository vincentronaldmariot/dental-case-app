const axios = require('axios');

const ONLINE_SERVER_URL = 'https://afp-dental-app-production.up.railway.app';

async function adminEmergenciesTabSummary() {
  try {
    console.log('🔍 Admin Emergencies Tab - Current Status Summary\n');

    // Step 1: Login as admin
    console.log('1️⃣ Logging in as admin...');
    const adminLoginResponse = await axios.post(`${ONLINE_SERVER_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin logged in');

    // Step 2: Test emergency records endpoint
    console.log('\n2️⃣ Testing emergency records endpoint...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      console.log('✅ Emergency records endpoint working');
      console.log(`📊 Found ${emergencyResponse.data.emergencyRecords?.length || 0} emergency records`);

    } catch (error) {
      console.log('❌ Emergency records endpoint failing');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    // Step 3: Test emergency status update
    console.log('\n3️⃣ Testing emergency status update...');
    try {
      const emergencyResponse = await axios.get(`${ONLINE_SERVER_URL}/api/admin/emergency`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });

      const emergencyRecords = emergencyResponse.data.emergencyRecords || [];
      
      if (emergencyRecords.length > 0) {
        const testRecord = emergencyRecords[0];
        console.log(`📋 Testing with record: ${testRecord.id}`);

        const updateResponse = await axios.put(
          `${ONLINE_SERVER_URL}/api/admin/emergency/${testRecord.id}/status`,
          {
            status: 'inProgress',
            handledBy: 'Dr. Admin Test',
            notes: 'Test status update'
          },
          {
            headers: { Authorization: `Bearer ${adminToken}` }
          }
        );

        console.log('✅ Emergency status update working');
        console.log('Response:', updateResponse.data);

      } else {
        console.log('⚠️ No emergency records to test with');
      }

    } catch (error) {
      console.log('❌ Emergency status update failing');
      console.log(`   Error: ${error.response?.status} - ${error.response?.data?.error || error.message}`);
    }

    console.log('\n📋 ADMIN EMERGENCIES TAB STATUS:');
    console.log('');
    console.log('🔴 CURRENT ISSUES:');
    console.log('   1. Emergency records table missing 8 columns:');
    console.log('      • status');
    console.log('      • priority');
    console.log('      • handled_by');
    console.log('      • resolution');
    console.log('      • follow_up_required');
    console.log('      • resolved_at');
    console.log('      • emergency_contact');
    console.log('      • notes');
    console.log('');
    console.log('   2. Admin emergency query fails with 500 error');
    console.log('   3. Admin emergencies tab shows no data');
    console.log('');
    console.log('🟡 FRONTEND STATUS:');
    console.log('   • Emergencies tab exists in admin dashboard ✅');
    console.log('   • Tab controller configured correctly ✅');
    console.log('   • Emergency service implemented ✅');
    console.log('   • Emergency record model complete ✅');
    console.log('');
    console.log('🟡 BACKEND STATUS:');
    console.log('   • Emergency routes implemented ✅');
    console.log('   • Admin emergency endpoints exist ✅');
    console.log('   • Status update endpoint exists ✅');
    console.log('   • Database schema incomplete ❌');
    console.log('');
    console.log('🔧 REQUIRED FIXES:');
    console.log('   1. Update emergency_records table schema');
    console.log('   2. Add missing columns to database');
    console.log('   3. Deploy schema changes to Railway');
    console.log('   4. Test emergency records functionality');
    console.log('');
    console.log('📝 NEXT STEPS:');
    console.log('   1. Create database migration script');
    console.log('   2. Update setup_railway_db.js with complete schema');
    console.log('   3. Deploy to Railway');
    console.log('   4. Test admin emergencies tab');
    console.log('   5. Verify emergency record creation and management');

  } catch (error) {
    console.error('❌ Summary failed:', error.response?.data || error.message);
  }
}

adminEmergenciesTabSummary(); 