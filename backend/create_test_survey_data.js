const { query } = require('./config/database');

async function createTestSurveyData() {
  try {
    console.log('🔧 Creating test survey data...');
    
    // Get a patient to associate with the survey
    const patients = await query('SELECT id FROM patients LIMIT 1');
    
    if (patients.rows.length === 0) {
      console.log('❌ No patients found. Please create a patient first.');
      return;
    }
    
    const patientId = patients.rows[0].id;
    console.log(`👤 Using patient ID: ${patientId}`);
    
    // Create test survey data with the 8-question format
    const testSurveyData = {
      question1: "Yes", // Do you experience tooth pain or sensitivity?
      question2: "No",  // Do you have bleeding gums when brushing?
      question3: "Sometimes", // Do you have bad breath or taste issues?
      question4: "No",  // Do you have loose or shifting teeth?
      question5: "Yes", // Do you have difficulty chewing or biting?
      question6: "No",  // Do you have jaw pain or clicking sounds?
      question7: "Sometimes", // Do you have dry mouth or excessive thirst?
      question8: "Yes", // Do you have any visible cavities or dark spots?
    };
    
    // Check if survey already exists for this patient
    const existingSurvey = await query(
      'SELECT id FROM dental_surveys WHERE patient_id = $1',
      [patientId]
    );
    
    if (existingSurvey.rows.length > 0) {
      console.log('📝 Updating existing survey data...');
      await query(
        'UPDATE dental_surveys SET survey_data = $1, completed_at = NOW() WHERE patient_id = $2',
        [JSON.stringify(testSurveyData), patientId]
      );
    } else {
      console.log('📝 Creating new survey data...');
      await query(
        'INSERT INTO dental_surveys (patient_id, survey_data, completed_at) VALUES ($1, $2, NOW())',
        [patientId, JSON.stringify(testSurveyData)]
      );
    }
    
    console.log('✅ Test survey data created successfully!');
    console.log('📊 Survey Data:', testSurveyData);
    
    // Verify the data was saved
    const savedSurvey = await query(
      'SELECT survey_data FROM dental_surveys WHERE patient_id = $1',
      [patientId]
    );
    
    if (savedSurvey.rows.length > 0) {
      console.log('✅ Survey data verified in database');
      console.log('📋 Saved Data:', savedSurvey.rows[0].survey_data);
    }
    
  } catch (error) {
    console.error('❌ Error creating test survey data:', error);
  }
}

// Run the function
createTestSurveyData().then(() => {
  console.log('\n🏁 Test survey data creation completed');
  process.exit(0);
}).catch((error) => {
  console.error('💥 Creation failed:', error);
  process.exit(1);
}); 