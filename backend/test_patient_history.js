const { query } = require('./config/database');

async function testPatientHistory() {
  try {
    console.log('🔍 Testing patient history query...');
    
    // First, let's check what tables exist
    console.log('\n📊 Checking existing tables...');
    const tablesResult = await query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    console.log('Available tables:');
    tablesResult.rows.forEach(row => {
      console.log(`  - ${row.table_name}`);
    });
    
    // Test the main patient query
    console.log('\n📊 Testing main patient query...');
    const patientsResult = await query(`
      SELECT 
        p.id,
        p.first_name,
        p.last_name,
        p.email,
        p.phone,
        p.classification,
        p.other_classification,
        p.serial_number,
        p.unit_assignment,
        p.address,
        p.emergency_contact,
        p.emergency_phone,
        p.medical_history,
        p.allergies,
        p.created_at,
        p.updated_at
      FROM patients p
      LIMIT 1
    `);
    
    console.log('✅ Main patient query successful');
    console.log('Sample patient data:', patientsResult.rows[0]);
    
    // Test appointments query
    console.log('\n📊 Testing appointments query...');
    const appointmentsResult = await query(`
      SELECT 
        id, service, appointment_date, time_slot, doctor_name, 
        status, notes, created_at, updated_at
      FROM appointments 
      LIMIT 1
    `);
    
    console.log('✅ Appointments query successful');
    console.log('Sample appointment data:', appointmentsResult.rows[0]);
    
    // Test dental_surveys query
    console.log('\n📊 Testing dental_surveys query...');
    const surveyResult = await query(`
      SELECT survey_data, completed_at, created_at
      FROM dental_surveys 
      LIMIT 1
    `);
    
    console.log('✅ Dental surveys query successful');
    console.log('Sample survey data:', surveyResult.rows[0]);
    
    // Test emergency_records query
    console.log('\n📊 Testing emergency_records query...');
    const emergencyResult = await query(`
      SELECT 
        id, pain_level, symptoms, urgency_level, status, 
        created_at, updated_at
      FROM emergency_records 
      LIMIT 1
    `);
    
    console.log('✅ Emergency records query successful');
    console.log('Sample emergency data:', emergencyResult.rows[0]);
    
    // Test treatment_records query
    console.log('\n📊 Testing treatment_records query...');
    const treatmentResult = await query(`
      SELECT 
        id, treatment_type, description, date_performed, 
        doctor_name, notes, created_at
      FROM treatment_records 
      LIMIT 1
    `);
    
    console.log('✅ Treatment records query successful');
    console.log('Sample treatment data:', treatmentResult.rows[0]);
    
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Full error:', error);
  } finally {
    process.exit(0);
  }
}

testPatientHistory(); 