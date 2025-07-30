const axios = require('axios');

// Test kiosk survey submission
async function testKioskSurveySubmission() {
  try {
    console.log('🧪 Testing kiosk survey submission...');
    
    const surveyData = {
      patient_info: {
        name: 'Test Patient',
        serial_number: 'TEST123',
        unit_assignment: 'Test Unit',
        contact_number: '09123456789',
        email: 'test@example.com',
        emergency_contact: 'Emergency Contact',
        emergency_phone: '09123456789',
        classification: 'Military',
        other_classification: '',
        last_visit: '2023-01-01'
      },
      tooth_conditions: {
        decayed_tooth: true,
        worn_down_tooth: false,
        impacted_tooth: false
      },
      tartar_level: 'MILD',
      tooth_pain: true,
      tooth_sensitive: false,
      damaged_fillings: {
        broken_tooth: false,
        broken_pasta: true
      },
      need_dentures: false,
      has_missing_teeth: true,
      missing_tooth_conditions: {
        missing_broken_tooth: false,
        missing_broken_pasta: false
      }
    };

    const response = await axios.post('https://afp-dental-app-production.up.railway.app/api/surveys', {
      surveyData: surveyData
    }, {
      headers: {
        'Authorization': 'Bearer kiosk_token',
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });

    console.log('✅ Survey submission successful!');
    console.log('Response status:', response.status);
    console.log('Response data:', response.data);
    
  } catch (error) {
    console.error('❌ Survey submission failed!');
    console.error('Error status:', error.response?.status);
    console.error('Error data:', error.response?.data);
    console.error('Error message:', error.message);
    
    if (error.code === 'ECONNABORTED') {
      console.error('Request timed out');
    }
  }
}

// Test the survey submission
testKioskSurveySubmission(); 