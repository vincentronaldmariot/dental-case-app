const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'dental_case_db',
  password: process.env.DB_PASSWORD || 'your_password',
  port: process.env.DB_PORT || 5432,
});

async function createEmergencyRecordsTable() {
  try {
    console.log('🔧 Creating emergency_records table...');

    const createTableQuery = `
      CREATE TABLE IF NOT EXISTS emergency_records (
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
      );
    `;

    const createIndexesQuery = `
      CREATE INDEX IF NOT EXISTS idx_emergency_records_patient_id ON emergency_records(patient_id);
      CREATE INDEX IF NOT EXISTS idx_emergency_records_status ON emergency_records(status);
      CREATE INDEX IF NOT EXISTS idx_emergency_records_priority ON emergency_records(priority);
      CREATE INDEX IF NOT EXISTS idx_emergency_records_reported_at ON emergency_records(reported_at);
    `;

    const createTriggerFunctionQuery = `
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = CURRENT_TIMESTAMP;
          RETURN NEW;
      END;
      $$ language 'plpgsql';
    `;

    const createTriggerQuery = `
      DROP TRIGGER IF EXISTS update_emergency_records_updated_at ON emergency_records;
      CREATE TRIGGER update_emergency_records_updated_at 
          BEFORE UPDATE ON emergency_records 
          FOR EACH ROW 
          EXECUTE FUNCTION update_updated_at_column();
    `;

    await pool.query(createTableQuery);
    console.log('✅ Emergency records table created successfully');

    await pool.query(createIndexesQuery);
    console.log('✅ Indexes created successfully');

    await pool.query(createTriggerFunctionQuery);
    console.log('✅ Trigger function created successfully');

    await pool.query(createTriggerQuery);
    console.log('✅ Trigger created successfully');

    // Check if table exists
    const checkTableQuery = `
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'emergency_records'
      );
    `;

    const result = await pool.query(checkTableQuery);
    console.log('📋 Emergency records table exists:', result.rows[0].exists);

    // Check table structure
    const structureResult = await pool.query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'emergency_records'
      ORDER BY ordinal_position
    `);

    console.log('📋 Emergency records table structure:');
    structureResult.rows.forEach((column, index) => {
      console.log(`${index + 1}. ${column.column_name} (${column.data_type}, nullable: ${column.is_nullable})`);
    });

  } catch (error) {
    console.error('❌ Error creating emergency records table:', error);
  } finally {
    await pool.end();
  }
}

createEmergencyRecordsTable(); 