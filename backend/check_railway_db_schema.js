const { Pool } = require('pg');

// Railway database configuration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || process.env.DATABASE_PUBLIC_URL,
  ssl: false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 60000,
});

async function checkRailwayDatabase() {
  try {
    console.log('🔍 Checking Railway database schema...');
    
    // Test connection
    const client = await pool.connect();
    console.log('✅ Connected to Railway database');
    
    // Check if dental_surveys table exists
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'dental_surveys'
      );
    `);
    
    if (tableCheck.rows[0].exists) {
      console.log('✅ dental_surveys table exists');
      
      // Check table structure
      const structure = await client.query(`
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns
        WHERE table_name = 'dental_surveys'
        ORDER BY ordinal_position;
      `);
      
      console.log('📋 Table structure:');
      structure.rows.forEach(row => {
        console.log(`   ${row.column_name}: ${row.data_type} (${row.is_nullable === 'YES' ? 'nullable' : 'not null'})`);
      });
      
      // Check if table has data
      const count = await client.query('SELECT COUNT(*) FROM dental_surveys');
      console.log(`📊 Survey records: ${count.rows[0].count}`);
      
      // Check for the kiosk patient ID
      const kioskCheck = await client.query(`
        SELECT id FROM dental_surveys 
        WHERE patient_id = '00000000-0000-0000-0000-000000000000'
      `);
      
      if (kioskCheck.rows.length > 0) {
        console.log('✅ Kiosk survey exists');
      } else {
        console.log('⚠️ No kiosk survey found');
      }
      
    } else {
      console.log('❌ dental_surveys table does not exist');
      console.log('🔧 Creating dental_surveys table...');
      
      // Create the table
      await client.query(`
        CREATE TABLE IF NOT EXISTS dental_surveys (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          patient_id UUID NOT NULL,
          survey_data JSONB NOT NULL,
          completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);
      
      console.log('✅ dental_surveys table created');
      
      // Create index
      await client.query(`
        CREATE INDEX IF NOT EXISTS idx_dental_surveys_patient_id 
        ON dental_surveys(patient_id);
      `);
      
      console.log('✅ Index created');
    }
    
    client.release();
    
  } catch (error) {
    console.error('❌ Database check failed:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

// Run the check
checkRailwayDatabase()
  .then(() => {
    console.log('\n✅ Railway database check completed');
  })
  .catch(error => {
    console.error('\n❌ Railway database check failed:', error);
    process.exit(1);
  }); 