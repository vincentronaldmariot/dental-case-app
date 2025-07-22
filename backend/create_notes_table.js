const { query } = require('./config/database');

async function createPatientNotesTable() {
  try {
    console.log('Creating patient_notes table...');
    
    // Create the table
    await query(`
      CREATE TABLE IF NOT EXISTS patient_notes (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
        admin_id UUID NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
        note TEXT NOT NULL,
        note_type VARCHAR(50) DEFAULT 'general' CHECK (note_type IN ('general', 'medical', 'appointment', 'treatment', 'emergency')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Create indexes
    await query('CREATE INDEX IF NOT EXISTS idx_patient_notes_patient_id ON patient_notes(patient_id)');
    await query('CREATE INDEX IF NOT EXISTS idx_patient_notes_created_at ON patient_notes(created_at)');
    
    // Create trigger function if it doesn't exist
    await query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
          NEW.updated_at = CURRENT_TIMESTAMP;
          RETURN NEW;
      END;
      $$ language 'plpgsql'
    `);
    
    // Create trigger
    await query(`
      DROP TRIGGER IF EXISTS update_patient_notes_updated_at ON patient_notes;
      CREATE TRIGGER update_patient_notes_updated_at 
        BEFORE UPDATE ON patient_notes 
        FOR EACH ROW 
        EXECUTE FUNCTION update_updated_at_column()
    `);
    
    console.log('✅ patient_notes table created successfully!');
    
  } catch (error) {
    console.error('❌ Error creating patient_notes table:', error);
  } finally {
    process.exit(0);
  }
}

createPatientNotesTable(); 