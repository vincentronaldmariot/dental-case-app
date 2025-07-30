const axios = require('axios');

// Test the Railway backend and force database schema fix
const RAILWAY_URL = 'https://afp-dental-app-production.up.railway.app';

async function forceDatabaseFix() {
  try {
    console.log('🧪 Forcing backend to fix database schema...');
    console.log('🔗 URL:', RAILWAY_URL);
    
    // Test data that will trigger the database schema fix
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

    console.log('📤 Submitting survey to trigger database fix...');
    
    const response = await axios.post(`${RAILWAY_URL}/api/surveys`, {
      surveyData: testSurveyData
    }, {
      headers: {
        'Authorization': 'Bearer kiosk_token',
        'Content-Type': 'application/json'
      },
      timeout: 60000 // 60 second timeout
    });

    console.log('✅ Survey submission successful!');
    console.log('📊 Response:', response.data);
    console.log('\n🎉 Database schema fix completed!');
    console.log('🚀 Your kiosk survey should now work!');
    
    return true;
    
  } catch (error) {
    console.error('❌ Survey submission failed:');
    
    if (error.response) {
      console.error('📊 Status:', error.response.status);
      console.error('📊 Data:', error.response.data);
      
      if (error.response.data && error.response.data.details && 
          error.response.data.details.includes('updated_at')) {
        console.log('\n🔧 The database schema issue is still present.');
        console.log('📋 This means the backend code fix hasn\'t been deployed properly.');
        console.log('🚀 Try redeploying the backend again.');
      }
    } else {
      console.error('❌ Network error:', error.message);
    }
    
    return false;
  }
}

// Run the test
forceDatabaseFix()
  .then(success => {
    if (success) {
      console.log('\n🎉 SUCCESS! The database schema has been fixed!');
    } else {
      console.log('\n⚠️ The issue persists. Let\'s try redeploying the backend.');
    }
  })
  .catch(error => {
    console.error('\n💥 Test error:', error);
  }); 