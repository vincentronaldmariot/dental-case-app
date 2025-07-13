const { query, testConnection, closePool } = require('../config/database');

const migrations = [
  // Patients table
  `
  CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    date_of_birth DATE NOT NULL,
    address TEXT,
    emergency_contact VARCHAR(100),
    emergency_phone VARCHAR(20),
    medical_history TEXT,
    allergies TEXT,
    serial_number VARCHAR(50),
    unit_assignment VARCHAR(100),
    classification VARCHAR(50),
    other_classification VARCHAR(100),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );
  `,

  // Dental surveys table
  `
  CREATE TABLE IF NOT EXISTS dental_surveys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    survey_data JSONB NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );
  `,

  // Appointments table
  `
  CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    service VARCHAR(100) NOT NULL,
    appointment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    time_slot VARCHAR(50) NOT NULL,
    doctor_name VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );
  `,

  // Treatment records table
  `
  CREATE TABLE IF NOT EXISTS treatment_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES appointments(id) ON DELETE SET NULL,
    treatment_type VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    doctor_name VARCHAR(100) NOT NULL,
    treatment_date TIMESTAMP WITH TIME ZONE NOT NULL,
    procedures TEXT[] DEFAULT '{}',
    notes TEXT,
    prescription TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );
  `,

  // Emergency records table
  `
  CREATE TABLE IF NOT EXISTS emergency_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    reported_at TIMESTAMP WITH TIME ZONE NOT NULL,
    emergency_type VARCHAR(50) NOT NULL,
    priority VARCHAR(20) NOT NULL,
    status VARCHAR(20) DEFAULT 'reported',
    description TEXT NOT NULL,
    pain_level INTEGER CHECK (pain_level >= 0 AND pain_level <= 10),
    symptoms TEXT[] DEFAULT '{}',
    location VARCHAR(100),
    duty_related BOOLEAN DEFAULT false,
    unit_command VARCHAR(100),
    handled_by VARCHAR(100),
    first_aid_provided TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolution TEXT,
    follow_up_required TEXT,
    emergency_contact VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );
  `,

  // Admin users table
  `
  CREATE TABLE IF NOT EXISTS admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(50) DEFAULT 'admin',
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
  );
  `,

  // Create indexes for better performance
  `
  CREATE INDEX IF NOT EXISTS idx_patients_email ON patients(email);
  CREATE INDEX IF NOT EXISTS idx_dental_surveys_patient_id ON dental_surveys(patient_id);
  CREATE INDEX IF NOT EXISTS idx_appointments_patient_id ON appointments(patient_id);
  CREATE INDEX IF NOT EXISTS idx_appointments_date ON appointments(appointment_date);
  CREATE INDEX IF NOT EXISTS idx_treatment_records_patient_id ON treatment_records(patient_id);
  CREATE INDEX IF NOT EXISTS idx_emergency_records_patient_id ON emergency_records(patient_id);
  CREATE INDEX IF NOT EXISTS idx_emergency_records_status ON emergency_records(status);
  `,

  // Create updated_at trigger function
  `
  CREATE OR REPLACE FUNCTION update_updated_at_column()
  RETURNS TRIGGER AS $$
  BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
  END;
  $$ language 'plpgsql';
  `,

  // Create triggers for updated_at
  `
  DROP TRIGGER IF EXISTS update_patients_updated_at ON patients;
  CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

  DROP TRIGGER IF EXISTS update_dental_surveys_updated_at ON dental_surveys;
  CREATE TRIGGER update_dental_surveys_updated_at BEFORE UPDATE ON dental_surveys FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

  DROP TRIGGER IF EXISTS update_appointments_updated_at ON appointments;
  CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

  DROP TRIGGER IF EXISTS update_treatment_records_updated_at ON treatment_records;
  CREATE TRIGGER update_treatment_records_updated_at BEFORE UPDATE ON treatment_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

  DROP TRIGGER IF EXISTS update_emergency_records_updated_at ON emergency_records;
  CREATE TRIGGER update_emergency_records_updated_at BEFORE UPDATE ON emergency_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

  DROP TRIGGER IF EXISTS update_admin_users_updated_at ON admin_users;
  CREATE TRIGGER update_admin_users_updated_at BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
  `
];

async function runMigrations() {
  console.log('🏗️  Starting database migrations...');
  
  try {
    await testConnection();
    
    for (let i = 0; i < migrations.length; i++) {
      console.log(`📊 Running migration ${i + 1}/${migrations.length}...`);
      await query(migrations[i]);
    }
    
    console.log('✅ All migrations completed successfully!');
    
    // Verify tables were created
    const result = await query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name;
    `);
    
    console.log('📋 Created tables:', result.rows.map(row => row.table_name));
    
  } catch (error) {
    console.error('❌ Migration failed:', error);
    process.exit(1);
  } finally {
    await closePool();
  }
}

// Run migrations if this script is executed directly
if (require.main === module) {
  runMigrations();
}

module.exports = { runMigrations }; 