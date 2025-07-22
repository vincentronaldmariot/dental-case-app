const http = require('http');

// Test the survey API endpoint
const testSurveyAPI = async () => {
  const adminToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

  // First, get a patient ID from the database
  const { query } = require('./backend/config/database.js');
  
  try {
    // Get a patient with survey data
    const patientResult = await query(`
      SELECT p.id, p.first_name, p.last_name, s.survey_data 
      FROM patients p 
      JOIN dental_surveys s ON s.patient_id = p.id 
      LIMIT 1
    `);
    
    if (patientResult.rows.length === 0) {
      console.log('❌ No patients with survey data found');
      return;
    }
    
    const patient = patientResult.rows[0];
    console.log('📋 Testing with patient:', patient.first_name, patient.last_name);
    console.log('📋 Patient ID:', patient.id);
    console.log('📋 Raw survey data from DB:', patient.survey_data);
    
    // Test the API endpoint
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: `/api/admin/patients/${patient.id}/survey`,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    };
    
    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        console.log('📊 API Response Status:', res.statusCode);
        console.log('📊 API Response Body:', data);
        
        try {
          const responseData = JSON.parse(data);
          console.log('📊 Parsed survey data:', responseData.surveyData);
        } catch (e) {
          console.log('❌ Error parsing response:', e.message);
        }
      });
    });
    
    req.on('error', (e) => {
      console.log('❌ Request error:', e.message);
    });
    
    req.end();
    
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
};

testSurveyAPI(); 