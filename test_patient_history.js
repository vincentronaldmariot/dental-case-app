const http = require('http');

// Test the patient history functionality
const testPatientHistory = async () => {
  const adminToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTI2MTAwMDIsImV4cCI6MTc1MzIxNDgwMn0.qqcSLZmigRJVFWGAhnonMMbV3PAlFx3ZxrY8tIky_jc';

  try {
    // Step 1: Get all patients
    console.log('📋 Step 1: Getting all patients...');
    const patientsResponse = await makeRequest('/api/admin/patients', 'GET', adminToken);
    
    if (patientsResponse.statusCode !== 200) {
      console.log('❌ Failed to get patients:', patientsResponse.statusCode);
      return;
    }
    
    const patientsData = JSON.parse(patientsResponse.body);
    const patients = patientsData.patients || patientsData;
    
    console.log(`✅ Found ${patients.length} patients`);
    
    // Step 2: Find a patient with survey data
    console.log('\n📋 Step 2: Finding patient with survey data...');
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
    
    const patient = patientWithSurvey.rows[0];
    console.log('✅ Found patient with survey:', patient.first_name, patient.last_name);
    console.log('📋 Patient ID:', patient.id);
    console.log('📋 Survey data:', patient.survey_data);
    
    // Step 3: Test the survey API for this patient
    console.log('\n📋 Step 3: Testing survey API...');
    const surveyResponse = await makeRequest(`/api/admin/patients/${patient.id}/survey`, 'GET', adminToken);
    
    console.log('📊 Survey API Status:', surveyResponse.statusCode);
    console.log('📊 Survey API Body:', surveyResponse.body);
    
    if (surveyResponse.statusCode === 200) {
      const surveyData = JSON.parse(surveyResponse.body);
      console.log('📊 Parsed survey data:', surveyData.surveyData);
      
      // Step 4: Check if the data matches what we expect
      console.log('\n📋 Step 4: Validating survey data...');
      const expectedKeys = ['question1', 'question2', 'question3', 'question4', 'question5', 'question6', 'question7', 'question8'];
      
      for (const key of expectedKeys) {
        if (surveyData.surveyData[key]) {
          console.log(`✅ ${key}: ${surveyData.surveyData[key]}`);
        } else {
          console.log(`❌ ${key}: Missing`);
        }
      }
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

testPatientHistory(); 