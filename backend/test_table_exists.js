const { query } = require('./config/database');

async function testAndCreateTable() {
  try {
    console.log('Testing if patient_notes table exists...');
    
    // Test if table exists
    const testResult = await query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'patient_notes'
      )
    `);
    
    const tableExists = testResult.rows[0].exists;
    console.log('Table exists:', tableExists);
    
    if (!tableExists) {
      console.log('Creating patient_notes table...');
      
      // Create the table
      await query(`
        CREATE TABLE patient_notes (
          id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
          patient_id UUID NOT NULL,
          admin_id UUID NOT NULL,
          note TEXT NOT NULL,
          note_type VARCHAR(50) DEFAULT 'general',
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
      `);
      
      // Add foreign key constraints
      await query(`
        ALTER TABLE patient_notes 
        ADD CONSTRAINT fk_patient_notes_patient_id 
        FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE
      `);
      
      await query(`
        ALTER TABLE patient_notes 
        ADD CONSTRAINT fk_patient_notes_admin_id 
        FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE CASCADE
      `);
      
      // Add check constraint
      await query(`
        ALTER TABLE patient_notes 
        ADD CONSTRAINT chk_note_type 
        CHECK (note_type IN ('general', 'medical', 'appointment', 'treatment', 'emergency'))
      `);
      
      console.log('✅ patient_notes table created successfully!');
    } else {
      console.log('✅ patient_notes table already exists!');
    }
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    process.exit(0);
  }
}

testAndCreateTable(); 