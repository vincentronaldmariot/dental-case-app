const axios = require('axios');

// Test the production Railway backend
const RAILWAY_URL = 'https://afp-dental-app-production.up.railway.app';

async function testSurveyFix() {
  try {
    console.log('🧪 Testing Railway backend survey submission...');
    console.log('🔗 URL:', RAILWAY_URL);
    
    // Test data that matches what the Flutter app sends
    const testSurveyData = {
      patient_info: {
        name: "Test User",
        serial_number: "",
        unit_assignment: "",
        contact_number: "09123456789",
        email: "test@example.com",
        emergency_contact: "Emergency Contact",
        emergency_phone: "09123456789",
        classification: "Others",
        other_classification: "Test Classification",
        last_visit: "2024-01-01"
      },
      tooth_conditions: {
        decayed_tooth: true,
        worn_down_tooth: false,
        impacted_tooth: false
      },
      tartar_level: "LIGHT",
      tooth_pain: true,
      tooth_sensitive: false,
      damaged_fillings: {
        broken_tooth: false,
        broken_pasta: false
      },
      need_dentures: false,
      has_missing_teeth: false,
      missing_tooth_conditions: {
        missing_broken_tooth: null,
        missing_broken_pasta: null
      }
    };

    console.log('📤 Submitting test survey...');
    
    const response = await axios.post(`${RAILWAY_URL}/api/surveys`, {
      surveyData: testSurveyData
    }, {
      headers: {
        'Authorization': 'Bearer kiosk_token',
        'Content-Type': 'application/json'
      },
      timeout: 30000
    });

    console.log('✅ Survey submission successful!');
    console.log('📊 Response status:', response.status);
    console.log('📊 Response data:', response.data);
    
    return true;
    
  } catch (error) {
    console.error('❌ Survey submission failed:');
    
    if (error.response) {
      console.error('📊 Status:', error.response.status);
      console.error('📊 Data:', error.response.data);
      
      // Check if it's the updated_at column error
      if (error.response.data && error.response.data.details && 
          error.response.data.details.includes('updated_at')) {
        console.log('\n🔧 This confirms the database schema issue needs to be fixed on Railway.');
        console.log('📋 The backend code has been updated to auto-fix this issue.');
        console.log('🚀 Deploy the updated backend to Railway to resolve this.');
      }
    } else {
      console.error('❌ Network error:', error.message);
    }
    
    return false;
  }
}

// Run the test
testSurveyFix()
  .then(success => {
    if (success) {
      console.log('\n🎉 Test passed! The database schema fix is working.');
    } else {
      console.log('\n⚠️ Test failed. The database schema still needs to be fixed on Railway.');
    }
  })
  .catch(error => {
    console.error('\n💥 Test error:', error);
  }); 