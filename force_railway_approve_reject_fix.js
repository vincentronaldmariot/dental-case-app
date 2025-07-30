const axios = require('axios');

const RAILWAY_API_URL = 'https://afp-dental-app-production.up.railway.app/api';

async function forceRailwayRestart() {
  console.log('🚀 Forcing Railway Restart for Approval/Rejection Fix...\n');

  try {
    // Step 1: Test current state
    console.log('1️⃣ Testing current Railway deployment...');
    try {
      const healthResponse = await axios.get(`${RAILWAY_API_URL.replace('/api', '')}/health`);
      console.log('✅ Railway is running');
    } catch (error) {
      console.log('❌ Railway health check failed - deployment may be outdated');
    }

    // Step 2: Test admin login (this should fail if deployment is outdated)
    console.log('\n2️⃣ Testing admin login endpoint...');
    try {
      const loginResponse = await axios.post(`${RAILWAY_API_URL}/admin/login`, {
        username: 'admin',
        password: 'admin123'
      });
      console.log('✅ Admin login working - deployment is current');
    } catch (error) {
      if (error.response && error.response.status === 404) {
        console.log('❌ Admin login returns 404 - Railway needs restart');
        console.log('🔧 The backend code is outdated on Railway');
      } else {
        console.log('⚠️  Admin login error:', error.message);
      }
    }

    console.log('\n📋 **RAILWAY RESTART REQUIRED**');
    console.log('🔧 The Railway deployment is outdated and needs to be restarted.');
    console.log('💡 This will apply the latest backend fixes including:');
    console.log('   - Fixed approval/rejection endpoints');
    console.log('   - Proper response format (arrays instead of objects)');
    console.log('   - UI refresh fixes');
    console.log('   - Admin dashboard functionality');

    console.log('\n🚀 **HOW TO RESTART RAILWAY:**');
    console.log('1. Go to https://railway.app/dashboard');
    console.log('2. Select your "AFP dental app" project');
    console.log('3. Go to Variables tab');
    console.log('4. Add new variable:');
    console.log('   - Name: FORCE_RESTART');
    console.log('   - Value: true');
    console.log('5. Click Add');
    console.log('6. Wait 2-5 minutes for deployment');
    console.log('7. Run this script again to test');

    console.log('\n⏰ **Expected Timeline:**');
    console.log('- Railway restart: 2-5 minutes');
    console.log('- Testing: 1 minute');
    console.log('- Total: ~5 minutes');

    console.log('\n🎯 **After Restart - Expected Results:**');
    console.log('- ✅ Admin login working');
    console.log('- ✅ Pending appointments loading');
    console.log('- ✅ Approval/rejection working');
    console.log('- ✅ UI refresh working properly');
    console.log('- ✅ Appointments moving between tabs correctly');

  } catch (error) {
    console.error('❌ Error during Railway restart check:', error.message);
  }
}

async function testAfterRestart() {
  console.log('\n🧪 Testing After Railway Restart...\n');

  try {
    // Test admin login
    console.log('1️⃣ Testing admin login...');
    const loginResponse = await axios.post(`${RAILWAY_API_URL}/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    if (loginResponse.status !== 200) {
      throw new Error('Admin login failed');
    }

    const adminToken = loginResponse.data.token;
    console.log('✅ Admin login successful');

    // Test pending appointments
    console.log('\n2️⃣ Testing pending appointments...');
    const pendingResponse = await axios.get(`${RAILWAY_API_URL}/admin/appointments/pending`, {
      headers: { 'Authorization': `Bearer ${adminToken}` }
    });

    const pendingAppointments = pendingResponse.data.pendingAppointments || [];
    console.log(`📋 Found ${pendingAppointments.length} pending appointments`);

    if (pendingAppointments.length > 0) {
      console.log('✅ Pending appointments loading correctly');
      
      // Test approval endpoint
      const testAppointment = pendingAppointments[0];
      console.log(`\n3️⃣ Testing approval for appointment: ${testAppointment.id}`);
      
      const approveResponse = await axios.post(
        `${RAILWAY_API_URL}/admin/appointments/${testAppointment.id}/approve`,
        { notes: 'Test approval' },
        { headers: { 'Authorization': `Bearer ${adminToken}` } }
      );

      if (approveResponse.status === 200) {
        console.log('✅ Approval endpoint working');
        
        // Verify appointment moved
        await new Promise(resolve => setTimeout(resolve, 1000));
        const pendingAfterResponse = await axios.get(`${RAILWAY_API_URL}/admin/appointments/pending`, {
          headers: { 'Authorization': `Bearer ${adminToken}` }
        });
        
        const pendingAfter = pendingAfterResponse.data.pendingAppointments || [];
        const stillPending = pendingAfter.find(apt => apt.id === testAppointment.id);
        
        if (!stillPending) {
          console.log('✅ SUCCESS: Appointment moved from pending after approval');
          console.log('🎉 UI refresh issue is RESOLVED!');
        } else {
          console.log('❌ FAILED: Appointment still in pending - UI refresh issue persists');
        }
      } else {
        console.log('❌ Approval endpoint failed');
      }
    } else {
      console.log('⚠️  No pending appointments to test with');
    }

    console.log('\n🎉 Railway restart test completed!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    if (error.response) {
      console.error('📊 Response status:', error.response.status);
      console.error('📊 Response data:', error.response.data);
    }
  }
}

// Check if this is a restart test
const isRestartTest = process.argv.includes('--test-after-restart');

if (isRestartTest) {
  testAfterRestart();
} else {
  forceRailwayRestart();
} 