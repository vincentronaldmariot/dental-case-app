const { query } = require('./backend/config/database');

async function checkAllTables() {
  try {
    console.log('🔍 Checking all tables in the database...');
    
    // Get all table names
    const tablesResult = await query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    
    console.log('📊 All tables in database:');
    tablesResult.rows.forEach(row => {
      console.log(`  - ${row.table_name}`);
    });
    
    // Check if specific tables exist
    const requiredTables = [
      'appointments',
      'dental_surveys', 
      'treatment_records',
      'emergency_records',
      'notifications',
      'patients',
      'admin_users'
    ];
    
    console.log('\n🔍 Checking required tables:');
    for (const tableName of requiredTables) {
      const existsResult = await query(`
        SELECT EXISTS (
          SELECT FROM information_schema.tables 
          WHERE table_schema = 'public' 
          AND table_name = $1
        )
      `, [tableName]);
      
      const exists = existsResult.rows[0].exists;
      console.log(`  - ${tableName}: ${exists ? '✅ EXISTS' : '❌ MISSING'}`);
    }
    
  } catch (error) {
    console.error('❌ Error checking tables:', error);
  }
}

checkAllTables(); 