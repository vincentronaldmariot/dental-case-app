const { query } = require('./backend/config/database');

async function testDatabaseConnection() {
  try {
    console.log('🔍 Testing database connection...');
    
    // Test basic connection
    const result = await query('SELECT NOW() as current_time');
    console.log('✅ Database connection successful');
    console.log('Current time:', result.rows[0].current_time);
    
    // Check if emergency_records table exists
    const tableCheck = await query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'emergency_records'
      );
    `);
    
    if (tableCheck.rows[0].exists) {
      console.log('✅ emergency_records table exists');
      
      // Check table structure
      const columns = await query(`
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_name = 'emergency_records'
        ORDER BY ordinal_position;
      `);
      
      console.log('📋 Table columns:');
      columns.rows.forEach(col => {
        console.log(`  ${col.column_name}: ${col.data_type}`);
      });
      
      // Check if there are any records
      const count = await query('SELECT COUNT(*) as count FROM emergency_records');
      console.log(`📊 Total records: ${count.rows[0].count}`);
      
      if (count.rows[0].count > 0) {
        // Try to get one record with the TO_CHAR format
        const sample = await query(`
          SELECT 
            id,
            TO_CHAR(reported_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as reported_at,
            emergency_type,
            status
          FROM emergency_records 
          LIMIT 1
        `);
        
        console.log('📄 Sample record:');
        console.log(JSON.stringify(sample.rows[0], null, 2));
      }
      
    } else {
      console.log('❌ emergency_records table does not exist');
    }
    
  } catch (error) {
    console.error('❌ Database error:', error);
  }
}

testDatabaseConnection(); 