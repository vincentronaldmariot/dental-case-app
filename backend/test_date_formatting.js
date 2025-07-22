const { query } = require('./config/database');

async function testDateFormatting() {
  try {
    console.log('🔍 Testing date formatting...');
    
    // Test 1: Check how dates are stored
    console.log('\n📋 Test 1: Check stored dates');
    const storedDates = await query('SELECT id, appointment_date FROM appointments ORDER BY appointment_date DESC LIMIT 5');
    console.log('Stored dates:');
    storedDates.rows.forEach(row => {
      console.log(`ID: ${row.id}, Date: ${row.appointment_date}`);
      console.log(`  - Type: ${typeof row.appointment_date}`);
      console.log(`  - Constructor: ${row.appointment_date.constructor.name}`);
      console.log(`  - ISO String: ${row.appointment_date.toISOString()}`);
      console.log(`  - Date part: ${row.appointment_date.toISOString().split('T')[0]}`);
    });
    
    // Test 2: Test date insertion with different formats
    console.log('\n📋 Test 2: Test date insertion with different formats');
    
    const testPatientId = '123e4567-e89b-12d3-a456-426614174000';
    const testDate = '2025-01-15';
    
    console.log('Inserting date:', testDate);
    
    const insertResult = await query(`
      INSERT INTO appointments (patient_id, service, appointment_date, time_slot, status)
      VALUES ($1, 'Test Service', ($2::date AT TIME ZONE 'Asia/Manila'), '10:00', 'pending')
      RETURNING id, appointment_date
    `, [testPatientId, testDate]);
    
    console.log('Inserted date:', insertResult.rows[0].appointment_date);
    console.log('Inserted date ISO:', insertResult.rows[0].appointment_date.toISOString());
    console.log('Inserted date part:', insertResult.rows[0].appointment_date.toISOString().split('T')[0]);
    
    // Test 3: Test date retrieval and formatting
    console.log('\n📋 Test 3: Test date retrieval and formatting');
    const retrievedDate = insertResult.rows[0].appointment_date;
    
    // Simulate the backend formatting
    const formattedDate = retrievedDate.toISOString().split('T')[0];
    console.log('Formatted date:', formattedDate);
    
    // Test 4: Test timezone conversion
    console.log('\n📋 Test 4: Test timezone conversion');
    const date = new Date(retrievedDate);
    console.log('JavaScript Date object:', date);
    console.log('Date.toISOString():', date.toISOString());
    console.log('Date.toLocaleString():', date.toLocaleString());
    
    // Test 5: Test different date formats
    console.log('\n📋 Test 5: Test different date formats');
    
    const formats = [
      '2025-01-15',
      '2025-01-15T00:00:00.000Z',
      '2025-01-15T00:00:00.000+08:00',
      '2025-01-15T00:00:00.000-08:00'
    ];
    
    for (const format of formats) {
      console.log(`\nTesting format: ${format}`);
      try {
        const testResult = await query(`
          SELECT ($1::date AT TIME ZONE 'Asia/Manila') as converted_date
        `, [format]);
        console.log(`  Converted: ${testResult.rows[0].converted_date}`);
        console.log(`  ISO: ${testResult.rows[0].converted_date.toISOString()}`);
        console.log(`  Date part: ${testResult.rows[0].converted_date.toISOString().split('T')[0]}`);
      } catch (e) {
        console.log(`  Error: ${e.message}`);
      }
    }
    
    // Clean up test data
    await query('DELETE FROM appointments WHERE patient_id = $1', [testPatientId]);
    console.log('\n✅ Test completed successfully!');
    
  } catch (error) {
    console.error('❌ Error in date formatting test:', error);
  }
}

testDateFormatting(); 