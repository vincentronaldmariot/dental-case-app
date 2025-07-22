const http = require('http');

// Comprehensive test of the entire flow
const comprehensiveTest = async () => {
  const adminToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

  try {
    console.log('🔍 Step 1: Testing Patients API...\n');
    
    // Test the patients API
    const patientsResponse = await makeRequest('/api/admin/patients', 'GET', adminToken);
    
    if (patientsResponse.statusCode !== 200) {
      console.log('❌ Patients API failed:', patientsResponse.statusCode);
      return;
    }
    
    const patientsData = JSON.parse(patientsResponse.body);
    const patients = patientsData.patients || patientsData;
    
    console.log(`✅ Found ${patients.length} patients`);
    
    // Find a patient with survey data
    console.log('\n🔍 Step 2: Finding patient with survey data...\n');
    const { query } = require('./backend/config/database.js');
    
    const patientWithSurvey = await query(`
      SELECT p.id, p.first_name, p.last_name, s.survey_data 
      FROM patients p 
      JOIN dental_surveys s ON s.patient_id = p.id 
      LIMIT 1
    `);
    
    if (patientWithSurvey.rows.length === 0) {
      console.log('❌ No patients with survey data found');
      return;
    }
    
    const dbPatient = patientWithSurvey.rows[0];
    console.log('✅ Found patient in database:');
    console.log(`  ID: ${dbPatient.id}`);
    console.log(`  Name: ${dbPatient.first_name} ${dbPatient.last_name}`);
    console.log(`  Survey: ${Object.keys(dbPatient.survey_data)}`);
    
    // Find this patient in the API response
    console.log('\n🔍 Step 3: Finding patient in API response...\n');
    const apiPatient = patients.find(p => p.id === dbPatient.id);
    
    if (!apiPatient) {
      console.log('❌ Patient not found in API response');
      console.log('Available patient IDs:', patients.map(p => p.id));
      return;
    }
    
    console.log('✅ Found patient in API response:');
    console.log(`  ID: ${apiPatient.id}`);
    console.log(`  Name: ${apiPatient.fullName}`);
    console.log(`  Keys: ${Object.keys(apiPatient)}`);
    
    // Test the survey API with this patient ID
    console.log('\n🔍 Step 4: Testing Survey API...\n');
    const surveyResponse = await makeRequest(`/api/admin/patients/${apiPatient.id}/survey`, 'GET', adminToken);
    
    console.log(`📊 Survey API Status: ${surveyResponse.statusCode}`);
    
    if (surveyResponse.statusCode === 200) {
      const surveyData = JSON.parse(surveyResponse.body);
      console.log('✅ Survey API Response:');
      console.log(`  Survey Data: ${JSON.stringify(surveyData.surveyData, null, 2)}`);
      console.log(`  Survey Keys: ${Object.keys(surveyData.surveyData || {})}`);
      console.log(`  Has question1: ${surveyData.surveyData?.question1 ? 'Yes' : 'No'}`);
      console.log(`  Question1 value: ${surveyData.surveyData?.question1}`);
    } else {
      console.log('❌ Survey API failed:', surveyResponse.body);
    }
    
    // Test with database patient ID directly
    console.log('\n🔍 Step 5: Testing with database patient ID...\n');
    const directSurveyResponse = await makeRequest(`/api/admin/patients/${dbPatient.id}/survey`, 'GET', adminToken);
    
    console.log(`📊 Direct Survey API Status: ${directSurveyResponse.statusCode}`);
    
    if (directSurveyResponse.statusCode === 200) {
      const directSurveyData = JSON.parse(directSurveyResponse.body);
      console.log('✅ Direct Survey API Response:');
      console.log(`  Survey Data: ${JSON.stringify(directSurveyData.surveyData, null, 2)}`);
    } else {
      console.log('❌ Direct Survey API failed:', directSurveyResponse.body);
    }
    
  } catch (error) {
    console.log('❌ Error:', error.message);
  }
};

// Helper function to make HTTP requests
const makeRequest = (path, method, token) => {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: path,
      method: method,
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };
    
    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: data
        });
      });
    });
    
    req.on('error', (e) => {
      reject(e);
    });
    
    req.end();
  });
};

comprehensiveTest(); 