const { query } = require('./backend/config/database');

async function testEmergencyQuery() {
  try {
    console.log('🔍 Testing emergency query...');
    
    // Get a patient ID from the database
    const patientResult = await query('SELECT id FROM patients LIMIT 1');
    if (patientResult.rows.length === 0) {
      console.log('❌ No patients found in database');
      return;
    }
    
    const patientId = patientResult.rows[0].id;
    console.log('✅ Found patient ID:', patientId);
    
    // Run the exact query from the emergency route
    const result = await query(`
      SELECT 
        id, 
        TO_CHAR(reported_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as reported_at,
        emergency_type, priority, status, description,
        pain_level, symptoms, location, duty_related, unit_command,
        handled_by, first_aid_provided, 
        CASE WHEN resolved_at IS NOT NULL 
          THEN TO_CHAR(resolved_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
          ELSE NULL 
        END as resolved_at,
        resolution,
        follow_up_required, emergency_contact, notes, 
        TO_CHAR(created_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
      FROM emergency_records 
      WHERE patient_id = $1
      ORDER BY reported_at DESC
    `, [patientId]);

    console.log('✅ Query executed successfully');
    console.log('📊 Records found:', result.rows.length);
    
    if (result.rows.length > 0) {
      console.log('📄 First record:');
      console.log(JSON.stringify(result.rows[0], null, 2));
    }
    
  } catch (error) {
    console.error('❌ Query error:', error);
  }
}

testEmergencyQuery(); 