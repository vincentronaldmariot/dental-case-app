const { query } = require('./config/database');

async function testSurveyData() {
  try {
    console.log('🔍 Testing survey data in database...');
    
    // Check if dental_surveys table exists
    const tableCheck = await query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'dental_surveys'
      );
    `);
    
    if (!tableCheck.rows[0].exists) {
      console.log('❌ dental_surveys table does not exist');
      return;
    }
    
    console.log('✅ dental_surveys table exists');
    
    // Get all survey data
    const surveys = await query('SELECT * FROM dental_surveys LIMIT 5');
    
    console.log(`📊 Found ${surveys.rows.length} survey records`);
    
    if (surveys.rows.length === 0) {
      console.log('❌ No survey data found in database');
      console.log('💡 You may need to create some test survey data');
      return;
    }
    
    // Display sample survey data
    surveys.rows.forEach((survey, index) => {
      console.log(`\n📋 Survey ${index + 1}:`);
      console.log(`   Patient ID: ${survey.patient_id}`);
      console.log(`   Survey Data:`, survey.survey_data);
      console.log(`   Completed At: ${survey.completed_at}`);
      
      // Try to parse the survey data
      if (survey.survey_data) {
        try {
          const parsed = typeof survey.survey_data === 'string' 
            ? JSON.parse(survey.survey_data) 
            : survey.survey_data;
          console.log(`   Parsed Data:`, parsed);
        } catch (e) {
          console.log(`   Parse Error: ${e.message}`);
        }
      }
    });
    
    // Get patients with surveys
    const patientsWithSurveys = await query(`
      SELECT p.id, p.first_name, p.last_name, ds.survey_data, ds.completed_at
      FROM patients p
      INNER JOIN dental_surveys ds ON p.id = ds.patient_id
      LIMIT 3
    `);
    
    console.log(`\n👥 Patients with surveys: ${patientsWithSurveys.rows.length}`);
    
    patientsWithSurveys.rows.forEach((patient, index) => {
      console.log(`\n👤 Patient ${index + 1}: ${patient.first_name} ${patient.last_name}`);
      console.log(`   ID: ${patient.id}`);
      console.log(`   Survey Data:`, patient.survey_data);
    });
    
  } catch (error) {
    console.error('❌ Error testing survey data:', error);
  }
}

// Run the test
testSurveyData().then(() => {
  console.log('\n🏁 Survey data test completed');
  process.exit(0);
}).catch((error) => {
  console.error('💥 Test failed:', error);
  process.exit(1);
}); 