const { Pool } = require('pg');

// Try to get connection details from environment or use the known values
const DATABASE_URL = process.env.DATABASE_URL || 'postgresql://postgres:glfJbkmkHHAAlKQqFzNtkMQjXO%20PjJthr@ballast.proxy.rlwy.net:27199/railway';

console.log('🔍 Attempting to connect to Railway database...');
console.log('🔗 Using connection string:', DATABASE_URL.replace(/:[^:@]*@/, ':****@'));

const pool = new Pool({
  connectionString: DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 60000,
});

async function fixDatabaseSchema() {
  const client = await pool.connect();
  
  try {
    console.log('✅ Connected successfully!');
    
    console.log('🔍 Checking dental_surveys table structure...');
    
    // Check if updated_at column exists
    const columnExists = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'dental_surveys' 
        AND column_name = 'updated_at'
      );
    `);
    
    if (!columnExists.rows[0].exists) {
      console.log('❌ updated_at column missing. Adding it...');
      
      await client.query(`
        ALTER TABLE dental_surveys 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
      `);
      
      console.log('✅ updated_at column added successfully!');
    } else {
      console.log('✅ updated_at column already exists');
    }
    
    // Check if created_at column exists
    const createdAtExists = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'dental_surveys' 
        AND column_name = 'created_at'
      );
    `);
    
    if (!createdAtExists.rows[0].exists) {
      console.log('❌ created_at column missing. Adding it...');
      
      await client.query(`
        ALTER TABLE dental_surveys 
        ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
      `);
      
      console.log('✅ created_at column added successfully!');
    } else {
      console.log('✅ created_at column already exists');
    }
    
    // Show current table structure
    console.log('\n📋 Current dental_surveys table structure:');
    const structure = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'dental_surveys'
      ORDER BY ordinal_position;
    `);
    
    structure.rows.forEach(row => {
      console.log(`  - ${row.column_name}: ${row.data_type} ${row.is_nullable === 'YES' ? '(nullable)' : '(not null)'} ${row.column_default ? `default: ${row.column_default}` : ''}`);
    });
    
    console.log('\n🎉 Database schema fix completed successfully!');
    console.log('🚀 Your kiosk survey should now work!');
    
  } catch (error) {
    console.error('❌ Error fixing database schema:', error);
    console.log('\n🔧 Connection details used:');
    console.log(`   Connection string: ${DATABASE_URL.replace(/:[^:@]*@/, ':****@')}`);
  } finally {
    client.release();
    await pool.end();
  }
}

fixDatabaseSchema(); 