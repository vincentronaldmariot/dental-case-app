const { query } = require('./config/database');

async function testTableExists() {
  try {
    console.log('Testing database connection and table structure...');
    
    // Test basic connection
    const testResult = await query('SELECT 1 as test');
    console.log('✅ Database connection working');
    
    // Check if notifications table exists
    const tableResult = await query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'notifications'
      ) as exists
    `);
    
    console.log(`Notifications table exists: ${tableResult.rows[0].exists}`);
    
    if (tableResult.rows[0].exists) {
      // Get table structure
      const structureResult = await query(`
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'notifications'
        ORDER BY ordinal_position
      `);
      
      console.log('\nTable structure:');
      structureResult.rows.forEach(row => {
        console.log(`  ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
      });
      
      // Count rows
      const countResult = await query('SELECT COUNT(*) as count FROM notifications');
      console.log(`\nTotal rows in notifications table: ${countResult.rows[0].count}`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

testTableExists(); 