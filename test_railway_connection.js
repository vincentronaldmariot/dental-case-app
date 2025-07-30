const axios = require('axios');

// Test the Railway backend connection
const RAILWAY_URL = 'https://afp-dental-app-production.up.railway.app';

async function testRailwayConnection() {
  try {
    console.log('🧪 Testing Railway backend connection...');
    console.log('🔗 URL:', RAILWAY_URL);
    
    // Test 1: Health check
    console.log('\n📡 Test 1: Health check...');
    const healthResponse = await axios.get(`${RAILWAY_URL}/health`, {
      timeout: 10000
    });
    console.log('✅ Health check passed:', healthResponse.status);
    
    // Test 2: Survey submission (this should trigger the database fix)
    console.log('\n📡 Test 2: Survey submission...');
    const testSurveyData = {
      patient_info: {
        name: "Test User",
        contact_number: "09123456789",
        email: "test@example.com",
        classification: "Others",
        other_classification: "Test"
      },
      tooth_conditions: { decayed_tooth: true },
      tartar_level: "LIGHT",
      tooth_pain: false,
      tooth_sensitive: false,
      damaged_fillings: { broken_tooth: false },
      need_dentures: false,
      has_missing_teeth: false,
      missing_tooth_conditions: {}
    };

    const surveyResponse = await axios.post(`${RAILWAY_URL}/api/surveys`, {
      surveyData: testSurveyData
    }, {
      headers: {
        'Authorization': 'Bearer kiosk_token',
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });

    console.log('✅ Survey submission successful!');
    console.log('📊 Response:', surveyResponse.data);
    
    return true;
    
  } catch (error) {
    console.error('❌ Test failed:');
    
    if (error.response) {
      console.error('📊 Status:', error.response.status);
      console.error('📊 Data:', error.response.data);
      
      if (error.response.data && error.response.data.details && 
          error.response.data.details.includes('updated_at')) {
        console.log('\n🔧 The database schema issue is still present.');
        console.log('📋 This means either:');
        console.log('   1. The DATABASE_URL variable is not set correctly');
        console.log('   2. The backend hasn\'t redeployed yet');
        console.log('   3. The database fix code hasn\'t been deployed');
      }
    } else {
      console.error('❌ Network error:', error.message);
    }
    
    return false;
  }
}

// Run the test
testRailwayConnection()
  .then(success => {
    if (success) {
      console.log('\n🎉 SUCCESS! The Railway connection and database fix are working!');
      console.log('🚀 Your kiosk survey should now work!');
    } else {
      console.log('\n⚠️ The issue persists. Let\'s check the deployment status.');
    }
  })
  .catch(error => {
    console.error('\n💥 Test error:', error);
  }); 