const { query } = require('./config/database');

async function setupRailwaySurveys() {
  try {
    console.log('🔧 Setting up dental_surveys table on Railway...');
    
    // Create dental_surveys table if it doesn't exist
    await query(`
      CREATE TABLE IF NOT EXISTS dental_surveys (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID NOT NULL UNIQUE,
        survey_data JSONB NOT NULL,
        completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    console.log('✅ dental_surveys table created/verified');
    
    // Create index for better performance
    await query(`
      CREATE INDEX IF NOT EXISTS idx_dental_surveys_patient_id 
      ON dental_surveys(patient_id);
    `);
    
    console.log('✅ Index created/verified');
    
    // Create trigger for updated_at
    await query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ language 'plpgsql';
    `);
    
    await query(`
      DROP TRIGGER IF EXISTS update_dental_surveys_updated_at ON dental_surveys;
      CREATE TRIGGER update_dental_surveys_updated_at 
      BEFORE UPDATE ON dental_surveys 
      FOR EACH ROW 
      EXECUTE FUNCTION update_updated_at_column();
    `);
    
    console.log('✅ Trigger created/verified');
    
    // Check if table has any data
    const countResult = await query('SELECT COUNT(*) FROM dental_surveys');
    console.log(`📊 Current survey records: ${countResult.rows[0].count}`);
    
    // Test insert a sample kiosk survey
    const testSurvey = {
      patient_info: {
        name: 'Test Kiosk User',
        email: 'kiosk@test.com',
        contact_number: '09123456789'
      },
      submitted_at: new Date().toISOString(),
      submitted_via: 'kiosk'
    };
    
    const testResult = await query(`
      INSERT INTO dental_surveys (patient_id, survey_data)
      VALUES ('00000000-0000-0000-0000-000000000000', $1)
      ON CONFLICT (patient_id) DO UPDATE SET
        survey_data = EXCLUDED.survey_data,
        updated_at = CURRENT_TIMESTAMP
      RETURNING id;
    `, [JSON.stringify(testSurvey)]);
    
    console.log('✅ Test survey inserted/updated');
    console.log('✅ Railway surveys setup completed successfully');
    
  } catch (error) {
    console.error('❌ Railway surveys setup failed:', error);
    throw error;
  }
}

// Run the setup
setupRailwaySurveys()
  .then(() => {
    console.log('\n✅ Railway surveys setup completed');
    process.exit(0);
  })
  .catch(error => {
    console.error('\n❌ Railway surveys setup failed:', error);
    process.exit(1);
  }); 