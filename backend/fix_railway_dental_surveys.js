const { Pool } = require('pg');

// Railway database configuration
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || process.env.DATABASE_PUBLIC_URL,
  ssl: false,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 60000,
});

async function fixRailwayDentalSurveys() {
  const client = await pool.connect();
  
  try {
    console.log('🔍 Connecting to Railway production database...');
    console.log('✅ Connected to Railway database');
    
    console.log('🔍 Checking dental_surveys table structure...');
    
    // Check if the table exists
    const tableExists = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'dental_surveys'
      );
    `);
    
    if (!tableExists.rows[0].exists) {
      console.log('❌ dental_surveys table does not exist. Creating it...');
      
      await client.query(`
        CREATE TABLE dental_surveys (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          patient_id UUID NOT NULL UNIQUE,
          survey_data JSONB NOT NULL,
          completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);
      
      console.log('✅ dental_surveys table created successfully');
    } else {
      console.log('✅ dental_surveys table exists');
      
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
        
        console.log('✅ updated_at column added successfully');
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
        
        console.log('✅ created_at column added successfully');
      } else {
        console.log('✅ created_at column already exists');
      }
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
    
    // Auto-create kiosk patient if it doesn't exist
    try {
      const existingPatient = await client.query(
        'SELECT id FROM patients WHERE id = $1',
        ['00000000-0000-0000-0000-000000000000']
      );
      
      if (existingPatient.rows.length === 0) {
        console.log('🔧 Auto-creating kiosk patient...');
        await client.query(`
          INSERT INTO patients (
            id, first_name, last_name, email, phone, password_hash, 
            date_of_birth, address, emergency_contact, emergency_phone,
            created_at, updated_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            'Kiosk',
            'User',
            'kiosk@dental.app',
            '00000000000',
            'kiosk_hash',
            '2000-01-01',
            'Kiosk Location',
            'Kiosk Emergency',
            '00000000000',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
          )
        `);
        console.log('✅ Kiosk patient auto-created');
      } else {
        console.log('✅ Kiosk patient already exists');
      }
    } catch (patientError) {
      console.error('❌ Failed to create kiosk patient:', patientError);
    }
    
    console.log('\n✅ Railway production database schema fix completed successfully!');
    
  } catch (error) {
    console.error('❌ Error fixing Railway dental_surveys table:', error);
  } finally {
    client.release();
    await pool.end();
  }
}

fixRailwayDentalSurveys(); 