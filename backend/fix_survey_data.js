const { query } = require('./config/database');

async function fixSurveyData() {
  try {
    console.log('🔧 Fixing survey data format...');
    
    // Get all surveys
    const surveys = await query('SELECT * FROM dental_surveys');
    console.log(`📊 Found ${surveys.rows.length} survey records`);
    
    for (let i = 0; i < surveys.rows.length; i++) {
      const survey = surveys.rows[i];
      console.log(`\n📋 Processing survey ${i + 1} for patient: ${survey.patient_id}`);
      
      let surveyData = survey.survey_data;
      
      // Parse if it's a string
      if (typeof surveyData === 'string') {
        try {
          surveyData = JSON.parse(surveyData);
        } catch (e) {
          console.log(`❌ Error parsing survey data: ${e.message}`);
          continue;
        }
      }
      
      // Convert to standard 8-question format
      const standardFormat = {
        question1: "Not specified",
        question2: "Not specified", 
        question3: "Not specified",
        question4: "Not specified",
        question5: "Not specified",
        question6: "Not specified",
        question7: "Not specified",
        question8: "Not specified"
      };
      
      // Map existing data to standard format
      if (surveyData) {
        // Map pain-related data to question 1
        if (surveyData.pain_level || surveyData.tooth_pain || surveyData.pain_assessment) {
          standardFormat.question1 = "Yes";
        }
        
        // Map bleeding gums to question 2
        if (surveyData.bleeding_gums) {
          standardFormat.question2 = surveyData.bleeding_gums ? "Yes" : "No";
        }
        
        // Map bad breath to question 3
        if (surveyData.bad_breath) {
          standardFormat.question3 = surveyData.bad_breath ? "Yes" : "No";
        }
        
        // Map loose teeth to question 4
        if (surveyData.loose_teeth) {
          standardFormat.question4 = surveyData.loose_teeth ? "Yes" : "No";
        }
        
        // Map chewing difficulty to question 5
        if (surveyData.chewing_difficulty) {
          standardFormat.question5 = surveyData.chewing_difficulty ? "Yes" : "No";
        }
        
        // Map jaw pain to question 6
        if (surveyData.jaw_pain) {
          standardFormat.question6 = surveyData.jaw_pain ? "Yes" : "No";
        }
        
        // Map dry mouth to question 7
        if (surveyData.dry_mouth) {
          standardFormat.question7 = surveyData.dry_mouth ? "Yes" : "No";
        }
        
        // Map cavities to question 8
        if (surveyData.visible_cavities) {
          standardFormat.question8 = surveyData.visible_cavities ? "Yes" : "No";
        }
        
        // If data is already in question format, use it
        if (surveyData.question1 || surveyData.question_1) {
          for (let j = 1; j <= 8; j++) {
            const key = `question${j}`;
            const altKey = `question_${j}`;
            if (surveyData[key]) {
              standardFormat[key] = surveyData[key];
            } else if (surveyData[altKey]) {
              standardFormat[key] = surveyData[altKey];
            }
          }
        }
      }
      
      // Update the survey data
      await query(
        'UPDATE dental_surveys SET survey_data = $1 WHERE id = $2',
        [JSON.stringify(standardFormat), survey.id]
      );
      
      console.log(`✅ Updated survey data:`, standardFormat);
    }
    
    console.log('\n🎉 All survey data has been standardized!');
    
    // Verify the changes
    const updatedSurveys = await query('SELECT * FROM dental_surveys LIMIT 3');
    console.log('\n📊 Verification - Sample updated surveys:');
    
    updatedSurveys.rows.forEach((survey, index) => {
      console.log(`\nSurvey ${index + 1}:`);
      console.log('Patient ID:', survey.patient_id);
      console.log('Survey Data:', survey.survey_data);
    });
    
  } catch (error) {
    console.error('❌ Error fixing survey data:', error);
  }
}

// Run the fix
fixSurveyData().then(() => {
  console.log('\n🏁 Survey data fix completed');
  process.exit(0);
}).catch((error) => {
  console.error('💥 Fix failed:', error);
  process.exit(1);
}); 