const { Pool } = require('pg');

// Enhanced SSL configuration for Railway
const getSSLConfig = () => {
  if (process.env.NODE_ENV !== 'production') {
    return false;
  }
  
  // For Railway, use a simpler SSL configuration
  return {
    rejectUnauthorized: false
  };
};

// Use DATABASE_PUBLIC_URL if available (for external connections), otherwise use DATABASE_URL
const dbConfig = (process.env.DATABASE_PUBLIC_URL || process.env.DATABASE_URL) ? {
  connectionString: process.env.DATABASE_PUBLIC_URL || process.env.DATABASE_URL,
  ssl: getSSLConfig(),
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 30000,
  query_timeout: 30000,
  statement_timeout: 30000
} : {
  host: process.env.PGHOST || process.env.DB_HOST || 'localhost',
  port: process.env.PGPORT || process.env.DB_PORT || 5432,
  database: process.env.PGDATABASE || process.env.DB_NAME || 'dental_case_db',
  user: process.env.PGUSER || process.env.DB_USER || 'dental_user',
  password: process.env.PGPASSWORD || process.env.DB_PASSWORD || 'dental_password',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 30000,
  ssl: getSSLConfig(),
};

const pool = new Pool(dbConfig);

async function deployEmergencySchema() {
  console.log('🚀 Deploying Emergency Records Schema to Railway...');
  
  try {
    const client = await pool.connect();
    console.log('✅ Connected to Railway PostgreSQL database');
    
    // Check if emergency_records table exists
    console.log('📋 Checking current emergency_records table...');
    const tableCheck = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'emergency_records'
      );
    `);
    
    const tableExists = tableCheck.rows[0].exists;
    console.log(`📊 Emergency records table exists: ${tableExists}`);
    
    if (tableExists) {
      // Get current table structure
      console.log('📋 Getting current table structure...');
      const structureResult = await client.query(`
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_name = 'emergency_records' 
        ORDER BY ordinal_position;
      `);
      
      console.log('📊 Current columns:');
      structureResult.rows.forEach(row => {
        console.log(`   - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
      });
      
      // Check for missing columns and add them
      const requiredColumns = [
        { name: 'status', type: 'VARCHAR(20)', default: "'reported'", check: "CHECK (status IN ('reported', 'triaged', 'in_progress', 'resolved', 'referred'))" },
        { name: 'priority', type: 'VARCHAR(20)', default: "'standard'", check: "CHECK (priority IN ('immediate', 'urgent', 'standard'))" },
        { name: 'handled_by', type: 'VARCHAR(100)', default: null },
        { name: 'resolution', type: 'TEXT', default: null },
        { name: 'follow_up_required', type: 'TEXT', default: null },
        { name: 'resolved_at', type: 'TIMESTAMP', default: null },
        { name: 'emergency_contact', type: 'VARCHAR(20)', default: null },
        { name: 'notes', type: 'TEXT', default: null },
        { name: 'pain_level', type: 'INTEGER', default: null, check: "CHECK (pain_level >= 0 AND pain_level <= 10)" },
        { name: 'symptoms', type: 'TEXT[]', default: null },
        { name: 'location', type: 'VARCHAR(100)', default: null },
        { name: 'duty_related', type: 'BOOLEAN', default: 'FALSE' },
        { name: 'unit_command', type: 'VARCHAR(100)', default: null },
        { name: 'first_aid_provided', type: 'TEXT', default: null },
        { name: 'updated_at', type: 'TIMESTAMP', default: 'CURRENT_TIMESTAMP' }
      ];
      
      const existingColumns = structureResult.rows.map(row => row.column_name);
      
      for (const column of requiredColumns) {
        if (!existingColumns.includes(column.name)) {
          console.log(`➕ Adding missing column: ${column.name}`);
          
          let alterQuery = `ALTER TABLE emergency_records ADD COLUMN ${column.name} ${column.type}`;
          if (column.default) {
            alterQuery += ` DEFAULT ${column.default}`;
          }
          if (column.check) {
            alterQuery += ` ${column.check}`;
          }
          
          await client.query(alterQuery);
          console.log(`✅ Added column: ${column.name}`);
        } else {
          console.log(`✅ Column already exists: ${column.name}`);
        }
      }
      
      // Check if we need to rename emergency_date to reported_at
      if (existingColumns.includes('emergency_date') && !existingColumns.includes('reported_at')) {
        console.log('🔄 Renaming emergency_date to reported_at...');
        await client.query(`ALTER TABLE emergency_records RENAME COLUMN emergency_date TO reported_at`);
        console.log('✅ Renamed emergency_date to reported_at');
      }
      
      // Check if we need to rename severity to pain_level
      if (existingColumns.includes('severity') && !existingColumns.includes('pain_level')) {
        console.log('🔄 Renaming severity to pain_level...');
        await client.query(`ALTER TABLE emergency_records RENAME COLUMN severity TO pain_level`);
        console.log('✅ Renamed severity to pain_level');
      }
      
      // Check if we need to change id from UUID to SERIAL
      const idCheck = await client.query(`
        SELECT data_type FROM information_schema.columns 
        WHERE table_name = 'emergency_records' AND column_name = 'id'
      `);
      
      if (idCheck.rows[0]?.data_type === 'uuid') {
        console.log('🔄 Converting id from UUID to SERIAL...');
        
                 // Drop any existing new table first
         await client.query(`DROP TABLE IF EXISTS emergency_records_new`);
         
         // Create a new table with SERIAL id
         await client.query(`
           CREATE TABLE emergency_records_new (
            id SERIAL PRIMARY KEY,
            patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
            reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            emergency_type VARCHAR(50) NOT NULL,
            priority VARCHAR(20) NOT NULL CHECK (priority IN ('immediate', 'urgent', 'standard')),
            status VARCHAR(20) DEFAULT 'reported' CHECK (status IN ('reported', 'triaged', 'in_progress', 'resolved', 'referred')),
            description TEXT NOT NULL,
            pain_level INTEGER CHECK (pain_level >= 0 AND pain_level <= 10),
            symptoms TEXT[],
            location VARCHAR(100),
            duty_related BOOLEAN DEFAULT FALSE,
            unit_command VARCHAR(100),
            handled_by VARCHAR(100),
            first_aid_provided TEXT,
            resolved_at TIMESTAMP,
            resolution TEXT,
            follow_up_required TEXT,
            emergency_contact VARCHAR(20),
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        `);
        
        // Copy data from old table to new table
        await client.query(`
          INSERT INTO emergency_records_new (
            patient_id, reported_at, emergency_type, priority, status, description,
            pain_level, symptoms, location, duty_related, unit_command, handled_by,
            first_aid_provided, resolved_at, resolution, follow_up_required,
            emergency_contact, notes, created_at, updated_at
          )
          SELECT 
            patient_id, 
            reported_at,
            emergency_type, 
            COALESCE(priority, 'standard') as priority,
            COALESCE(status, 'reported') as status,
            description,
            pain_level,
            symptoms,
            location,
            COALESCE(duty_related, false) as duty_related,
            unit_command,
            handled_by,
            first_aid_provided,
            resolved_at,
            resolution,
            follow_up_required,
            emergency_contact,
            notes,
            created_at,
            COALESCE(updated_at, created_at) as updated_at
          FROM emergency_records
        `);
        
        // Drop old table and rename new table
        await client.query(`DROP TABLE emergency_records`);
        await client.query(`ALTER TABLE emergency_records_new RENAME TO emergency_records`);
        
        console.log('✅ Converted id from UUID to SERIAL');
      }
      
    } else {
      // Create new table with complete schema
      console.log('📋 Creating emergency_records table with complete schema...');
      await client.query(`
        CREATE TABLE emergency_records (
          id SERIAL PRIMARY KEY,
          patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
          reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          emergency_type VARCHAR(50) NOT NULL,
          priority VARCHAR(20) NOT NULL CHECK (priority IN ('immediate', 'urgent', 'standard')),
          status VARCHAR(20) DEFAULT 'reported' CHECK (status IN ('reported', 'triaged', 'in_progress', 'resolved', 'referred')),
          description TEXT NOT NULL,
          pain_level INTEGER CHECK (pain_level >= 0 AND pain_level <= 10),
          symptoms TEXT[],
          location VARCHAR(100),
          duty_related BOOLEAN DEFAULT FALSE,
          unit_command VARCHAR(100),
          handled_by VARCHAR(100),
          first_aid_provided TEXT,
          resolved_at TIMESTAMP,
          resolution TEXT,
          follow_up_required TEXT,
          emergency_contact VARCHAR(20),
          notes TEXT,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      console.log('✅ Created emergency_records table');
    }
    
    // Create indexes
    console.log('📋 Creating indexes...');
    await client.query(`CREATE INDEX IF NOT EXISTS idx_emergency_records_patient_id ON emergency_records(patient_id)`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_emergency_records_status ON emergency_records(status)`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_emergency_records_priority ON emergency_records(priority)`);
    await client.query(`CREATE INDEX IF NOT EXISTS idx_emergency_records_reported_at ON emergency_records(reported_at)`);
    console.log('✅ Created indexes');
    
    // Create trigger function for updated_at
    console.log('📋 Creating trigger function...');
    await client.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = CURRENT_TIMESTAMP;
          RETURN NEW;
      END;
      $$ language 'plpgsql'
    `);
    
    // Create trigger for emergency_records
    await client.query(`
      DROP TRIGGER IF EXISTS update_emergency_records_updated_at ON emergency_records
    `);
    await client.query(`
      CREATE TRIGGER update_emergency_records_updated_at 
        BEFORE UPDATE ON emergency_records 
        FOR EACH ROW 
        EXECUTE FUNCTION update_updated_at_column()
    `);
    console.log('✅ Created trigger');
    
    // Verify the final table structure
    console.log('📋 Verifying final table structure...');
    const finalStructure = await client.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'emergency_records' 
      ORDER BY ordinal_position;
    `);
    
    console.log('📊 Final table structure:');
    finalStructure.rows.forEach(row => {
      console.log(`   - ${row.column_name}: ${row.data_type} (nullable: ${row.is_nullable})`);
    });
    
    // Check record count
    const recordCount = await client.query(`SELECT COUNT(*) as count FROM emergency_records`);
    console.log(`📊 Total emergency records: ${recordCount.rows[0].count}`);
    
    client.release();
    console.log('🎉 Emergency schema deployment completed successfully!');
    console.log('');
    console.log('✅ All required columns are now present:');
    console.log('   • status (reported, triaged, in_progress, resolved, referred)');
    console.log('   • priority (immediate, urgent, standard)');
    console.log('   • handled_by (who handled the emergency)');
    console.log('   • resolution (how it was resolved)');
    console.log('   • follow_up_required (follow-up instructions)');
    console.log('   • resolved_at (when it was resolved)');
    console.log('   • emergency_contact (contact information)');
    console.log('   • notes (additional notes)');
    console.log('   • pain_level (1-10 scale)');
    console.log('   • symptoms (array of symptoms)');
    console.log('   • location (where emergency occurred)');
    console.log('   • duty_related (if duty-related)');
    console.log('   • unit_command (military unit)');
    console.log('   • first_aid_provided (first aid given)');
    console.log('   • updated_at (automatic timestamp)');
    
  } catch (error) {
    console.error('❌ Error deploying emergency schema:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

// Run the deployment
deployEmergencySchema().catch(console.error); 