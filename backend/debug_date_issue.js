const { query } = require('./config/database');

async function debugDateIssue() {
  try {
    console.log('🔍 Debugging date issue...');
    
    // Test 1: Check current database timezone
    console.log('\n📅 Test 1: Database timezone');
    const timezoneResult = await query('SELECT CURRENT_TIMESTAMP, CURRENT_TIMESTAMP AT TIME ZONE \'Asia/Manila\' as ph_time');
    console.log('Current DB time:', timezoneResult.rows[0].current_timestamp);
    console.log('Philippine time:', timezoneResult.rows[0].ph_time);
    
    // Test 2: Check how dates are stored
    console.log('\n📅 Test 2: Check stored dates');
    const storedDates = await query('SELECT id, appointment_date FROM appointments ORDER BY appointment_date DESC LIMIT 5');
    console.log('Stored dates:');
    storedDates.rows.forEach(row => {
      console.log(`ID: ${row.id}, Date: ${row.appointment_date}`);
    });
    
    // Test 3: Test date insertion with timezone
    console.log('\n📅 Test 3: Test date insertion');
    const testDate = '2024-01-15';
    console.log('Inserting date:', testDate);
    
    // Use a valid UUID for testing
    const testPatientId = '123e4567-e89b-12d3-a456-426614174000';
    
    const insertResult = await query(`
      INSERT INTO appointments (patient_id, service, appointment_date, time_slot, status)
      VALUES ($1, 'Test Service', ($2::date AT TIME ZONE 'Asia/Manila'), '10:00', 'pending')
      RETURNING id, appointment_date
    `, [testPatientId, testDate]);
    
    console.log('Inserted date:', insertResult.rows[0].appointment_date);
    
    // Test 4: Test date retrieval and formatting
    console.log('\n📅 Test 4: Test date retrieval');
    const retrievedDate = insertResult.rows[0].appointment_date;
    console.log('Raw retrieved date:', retrievedDate);
    console.log('Retrieved date type:', typeof retrievedDate);
    console.log('Retrieved date constructor:', retrievedDate.constructor.name);
    
    // Simulate the backend formatting
    const date = new Date(retrievedDate);
    console.log('JavaScript Date object:', date);
    console.log('Date.toISOString():', date.toISOString());
    console.log('Date.toLocaleString():', date.toLocaleString());
    
    const philippineDate = new Date(date.toLocaleString("en-US", {timeZone: "Asia/Manila"}));
    console.log('Philippine Date object:', philippineDate);
    console.log('Formatted date:', philippineDate.toISOString().split('T')[0]);
    
    // Test 5: Test different timezone approaches
    console.log('\n📅 Test 5: Test different timezone approaches');
    
    // Approach 1: Direct timezone conversion
    const approach1 = new Date(retrievedDate.toLocaleString("en-US", {timeZone: "Asia/Manila"}));
    console.log('Approach 1:', approach1.toISOString().split('T')[0]);
    
    // Approach 2: Using UTC methods
    const approach2 = new Date(retrievedDate.getTime() + (8 * 60 * 60 * 1000)); // Add 8 hours
    console.log('Approach 2:', approach2.toISOString().split('T')[0]);
    
    // Approach 3: Using date-fns or moment.js approach
    const year = retrievedDate.getFullYear();
    const month = retrievedDate.getMonth() + 1;
    const day = retrievedDate.getDate();
    const approach3 = `${year}-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}`;
    console.log('Approach 3:', approach3);
    
    // Approach 4: Simple string manipulation
    const approach4 = retrievedDate.toISOString().split('T')[0];
    console.log('Approach 4:', approach4);
    
    // Clean up test data
    await query('DELETE FROM appointments WHERE patient_id = $1', [testPatientId]);
    
  } catch (error) {
    console.error('❌ Error in debug script:', error);
  }
}

debugDateIssue(); 