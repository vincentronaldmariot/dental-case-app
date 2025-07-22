const http = require('http');

async function testSurveyAPI() {
  try {
    console.log('🔍 Testing survey API endpoint...');
    
    // Get a patient ID from the database first
    const { query } = require('./config/database');
    const patients = await query('SELECT id FROM patients LIMIT 1');
    
    if (patients.rows.length === 0) {
      console.log('❌ No patients found');
      return;
    }
    
    const patientId = patients.rows[0].id;
    console.log(`👤 Testing with patient ID: ${patientId}`);
    
    // Test the survey API endpoint
    const adminToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';
    
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: `/api/admin/patients/${patientId}/survey`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    };
    
    const req = http.request(options, (res) => {
      console.log(`📡 API Response Status: ${res.statusCode}`);
      
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const response = JSON.parse(data);
          console.log('✅ API Response:');
          console.log(JSON.stringify(response, null, 2));
          
          if (response.surveyData) {
            console.log('\n📊 Survey Data Found:');
            console.log('Keys:', Object.keys(response.surveyData));
            
            // Check if it has the expected question format
            for (let i = 1; i <= 8; i++) {
              const key = `question${i}`;
              if (response.surveyData[key]) {
                console.log(`${key}: ${response.surveyData[key]}`);
              }
            }
          } else {
            console.log('❌ No survey data in response');
          }
        } catch (e) {
          console.log('❌ Error parsing response:', e.message);
          console.log('Raw response:', data);
        }
      });
    });
    
    req.on('error', (e) => {
      console.error('❌ Request error:', e.message);
    });
    
    req.end();
    
  } catch (error) {
    console.error('❌ Test error:', error);
  }
}

// Run the test
testSurveyAPI().then(() => {
  console.log('\n🏁 Survey API test completed');
  process.exit(0);
}).catch((error) => {
  console.error('💥 Test failed:', error);
  process.exit(1);
}); 