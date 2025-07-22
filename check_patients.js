const { query } = require('./backend/config/database.js');

async function checkPatients() {
  try {
    console.log('🔍 Checking patients and survey data...\n');
    
    // Get patients with survey data
    const result = await query(`
      SELECT p.id, p.first_name, p.last_name, s.survey_data 
      FROM patients p 
      LEFT JOIN dental_surveys s ON s.patient_id = p.id 
      LIMIT 5
    `);
    
    console.log(`Found ${result.rows.length} patients:\n`);
    
    result.rows.forEach((row, i) => {
      console.log(`Patient ${i + 1}:`);
      console.log(`  ID: ${row.id}`);
      console.log(`  Name: ${row.first_name} ${row.last_name}`);
      console.log(`  Has Survey: ${row.survey_data ? 'Yes' : 'No'}`);
      
      if (row.survey_data) {
        console.log(`  Survey Keys: ${Object.keys(row.survey_data)}`);
        console.log(`  Survey Data: ${JSON.stringify(row.survey_data, null, 2)}`);
      }
      console.log('---');
    });
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

checkPatients(); 