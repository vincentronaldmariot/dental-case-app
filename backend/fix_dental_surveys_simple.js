const { query, testConnection } = require('./config/database');

async function fixDentalSurveysTable() {
  try {
    console.log('🔍 Testing database connection...');
    await testConnection();
    
    console.log('🔍 Checking dental_surveys table structure...');
    
    // Check if the table exists
    const tableExists = await query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'dental_surveys'
      );
    `);
    
    if (!tableExists.rows[0].exists) {
      console.log('❌ dental_surveys table does not exist. Creating it...');
      
      await query(`
        CREATE TABLE dental_surveys (
          id SERIAL PRIMARY KEY,
          patient_id INTEGER,
          name VARCHAR(255),
          age INTEGER,
          gender VARCHAR(50),
          phone VARCHAR(20),
          address TEXT,
          classification VARCHAR(100),
          other_classification VARCHAR(255),
          missing_teeth TEXT,
          missing_tooth_conditions TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
      `);
      
      console.log('✅ dental_surveys table created successfully');
    } else {
      console.log('✅ dental_surveys table exists');
      
      // Check if updated_at column exists
      const columnExists = await query(`
        SELECT EXISTS (
          SELECT FROM information_schema.columns 
          WHERE table_schema = 'public' 
          AND table_name = 'dental_surveys' 
          AND column_name = 'updated_at'
        );
      `);
      
      if (!columnExists.rows[0].exists) {
        console.log('❌ updated_at column missing. Adding it...');
        
        await query(`
          ALTER TABLE dental_surveys 
          ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
        `);
        
        console.log('✅ updated_at column added successfully');
      } else {
        console.log('✅ updated_at column already exists');
      }
      
      // Check if created_at column exists
      const createdAtExists = await query(`
        SELECT EXISTS (
          SELECT FROM information_schema.columns 
          WHERE table_schema = 'public' 
          AND table_name = 'dental_surveys' 
          AND column_name = 'created_at'
        );
      `);
      
      if (!createdAtExists.rows[0].exists) {
        console.log('❌ created_at column missing. Adding it...');
        
        await query(`
          ALTER TABLE dental_surveys 
          ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;
        `);
        
        console.log('✅ created_at column added successfully');
      } else {
        console.log('✅ created_at column already exists');
      }
    }
    
    // Show current table structure
    console.log('\n📋 Current dental_surveys table structure:');
    const structure = await query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_schema = 'public' 
      AND table_name = 'dental_surveys'
      ORDER BY ordinal_position;
    `);
    
    structure.rows.forEach(row => {
      console.log(`  - ${row.column_name}: ${row.data_type} ${row.is_nullable === 'YES' ? '(nullable)' : '(not null)'} ${row.column_default ? `default: ${row.column_default}` : ''}`);
    });
    
    console.log('\n✅ Database schema fix completed successfully!');
    
  } catch (error) {
    console.error('❌ Error fixing dental_surveys table:', error);
  }
}

fixDentalSurveysTable(); 