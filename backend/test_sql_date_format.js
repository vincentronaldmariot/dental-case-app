const { Pool } = require('pg');
require('dotenv').config();

async function testSQLDateFormat() {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
  });

  try {
    console.log('Testing SQL date formatting fix...');
    
    // Test the exact query we fixed in the admin route
    const query = `
      SELECT
        er.id, er.patient_id,
        TO_CHAR(er.reported_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as reported_at,
        er.emergency_type, er.priority,
        er.status, er.description, er.pain_level, er.symptoms, er.location,
        er.duty_related, er.unit_command, er.handled_by, er.first_aid_provided,
        CASE WHEN er.resolved_at IS NOT NULL
          THEN TO_CHAR(er.resolved_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
          ELSE NULL
        END as resolved_at,
        er.resolution, er.follow_up_required, er.emergency_contact,
        er.notes,
        TO_CHAR(er.created_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at,
        p.first_name, p.last_name, p.phone, p.email
      FROM emergency_records er
      LEFT JOIN patients p ON er.patient_id = p.id
      ORDER BY er.reported_at DESC
      LIMIT 5
    `;
    
    const result = await pool.query(query);
    
    console.log(`✅ Found ${result.rows.length} emergency records`);
    
    if (result.rows.length > 0) {
      console.log('\n📅 Sample emergency record with formatted dates:');
      const sample = result.rows[0];
      console.log('ID:', sample.id);
      console.log('Patient:', sample.first_name, sample.last_name);
      console.log('Reported at (formatted):', sample.reported_at);
      console.log('Created at (formatted):', sample.created_at);
      console.log('Resolved at (formatted):', sample.resolved_at);
      
      // Test parsing the formatted date
      if (sample.reported_at) {
        const parsedDate = new Date(sample.reported_at);
        console.log('\n🔍 Date parsing test:');
        console.log('Original string:', sample.reported_at);
        console.log('Parsed as Date:', parsedDate.toISOString());
        console.log('Local Manila time:', parsedDate.toLocaleString('en-US', { timeZone: 'Asia/Manila' }));
        
        // Check if it's in the correct format
        if (sample.reported_at.includes('T') && sample.reported_at.includes('Z')) {
          console.log('✅ Date format is correct (ISO 8601 with timezone)');
        } else {
          console.log('❌ Date format may have issues');
        }
      }
    } else {
      console.log('No emergency records found in database');
    }
    
  } catch (error) {
    console.error('❌ Error testing SQL date format:', error.message);
  } finally {
    await pool.end();
  }
}

// Run the test
testSQLDateFormat(); 