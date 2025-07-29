const { Pool } = require('pg');
const bcrypt = require('bcrypt');

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
  connectionTimeoutMillis: 30000, // Increased timeout for SSL
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
  connectionTimeoutMillis: 30000, // Increased timeout for SSL
  ssl: getSSLConfig(),
};

const pool = new Pool(dbConfig);

async function setupDatabase() {
  console.log('🗄️ Setting up Railway database...');
  
  try {
    // Test connection
    const client = await pool.connect();
    console.log('✅ Connected to Railway PostgreSQL database');
    
    // Create admin_users table
    console.log('📋 Creating admin_users table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS admin_users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        username VARCHAR(50) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        full_name VARCHAR(100) NOT NULL,
        role VARCHAR(20) DEFAULT 'admin',
        is_active BOOLEAN DEFAULT true,
        last_login TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ admin_users table created');
    
    // Create patients table
    console.log('📋 Creating patients table...');
    await client.query(`
      CREATE TABLE IF NOT EXISTS patients (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        first_name VARCHAR(50) NOT NULL,
        last_name VARCHAR(50) NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        phone VARCHAR(20),
        password_hash VARCHAR(255) NOT NULL,
        date_of_birth DATE NOT NULL,
        gender VARCHAR(10),
        address TEXT,
        emergency_contact_name VARCHAR(100),
        emergency_contact_phone VARCHAR(20),
        medical_history TEXT,
        allergies TEXT,
        current_medications TEXT,
        insurance_provider VARCHAR(100),
        insurance_number VARCHAR(50),
        occupation VARCHAR(100),
        marital_status VARCHAR(20),
        blood_type VARCHAR(5),
        height INTEGER,
        weight INTEGER,
        classification VARCHAR(50),
        serial_number VARCHAR(50),
        unit_assignment VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ patients table created');
    
    // Create other tables
    console.log('📋 Creating other tables...');
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS dental_surveys (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
        survey_data JSONB NOT NULL,
        completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS appointments (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
        appointment_date TIMESTAMP NOT NULL,
        appointment_type VARCHAR(100),
        status VARCHAR(20) DEFAULT 'scheduled',
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS treatment_records (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
        treatment_date TIMESTAMP NOT NULL,
        treatment_type VARCHAR(100),
        description TEXT,
        dentist_name VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS emergency_records (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
        emergency_date TIMESTAMP NOT NULL,
        emergency_type VARCHAR(100),
        description TEXT,
        severity VARCHAR(20),
        resolved BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
        title VARCHAR(200) NOT NULL,
        message TEXT NOT NULL,
        type VARCHAR(50),
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    await client.query(`
      CREATE TABLE IF NOT EXISTS patient_notes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
        note_text TEXT NOT NULL,
        created_by VARCHAR(100),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    console.log('✅ All tables created successfully');
    
    // Create admin user
    console.log('👤 Creating admin user...');
    const passwordHash = await bcrypt.hash('admin123', 12);
    await client.query(`
      INSERT INTO admin_users (username, password_hash, full_name, role)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (username) DO NOTHING
    `, ['admin', passwordHash, 'System Administrator', 'admin']);
    console.log('✅ Admin user created');
    
    // Create test patients
    console.log('👥 Creating test patients...');
    const patientPasswordHash = await bcrypt.hash('password123', 12);
    
    await client.query(`
      INSERT INTO patients (first_name, last_name, email, phone, password_hash, date_of_birth)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (email) DO NOTHING
    `, ['John', 'Doe', 'john.doe@test.com', '123-456-7890', patientPasswordHash, '1990-01-15']);
    
    await client.query(`
      INSERT INTO patients (first_name, last_name, email, phone, password_hash, date_of_birth)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (email) DO NOTHING
    `, ['Jane', 'Smith', 'jane.smith@test.com', '234-567-8901', patientPasswordHash, '1985-05-20']);
    
    await client.query(`
      INSERT INTO patients (first_name, last_name, email, phone, password_hash, date_of_birth)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (email) DO NOTHING
    `, ['VIP', 'Person', 'vip.person@test.com', '345-678-9012', patientPasswordHash, '1980-12-10']);
    
    await client.query(`
      INSERT INTO patients (first_name, last_name, email, phone, password_hash, date_of_birth)
      VALUES ($1, $2, $3, $4, $5, $6)
      ON CONFLICT (email) DO NOTHING
    `, ['Jovelson Viper', 'Estrada', 'viperson1@gmail.com', '09123456789', patientPasswordHash, '1985-03-15']);
    
    console.log('✅ Test patients created');
    
    client.release();
    console.log('🎉 Railway database setup completed successfully!');
    console.log('');
    console.log('📋 Login Credentials:');
    console.log('');
    console.log('👨‍💼 Admin:');
    console.log('   Username: admin');
    console.log('   Password: admin123');
    console.log('');
    console.log('👤 Patients:');
    console.log('   Email: john.doe@test.com');
    console.log('   Password: password123');
    console.log('');
    console.log('   Email: jane.smith@test.com');
    console.log('   Password: password123');
    console.log('');
    console.log('   Email: vip.person@test.com');
    console.log('   Password: password123');
    console.log('');
    console.log('   Email: viperson1@gmail.com');
    console.log('   Password: password123');
    
  } catch (error) {
    console.error('❌ Database setup failed:', error);
    throw error;
  } finally {
    await pool.end();
  }
}

// Run if this script is executed directly
if (require.main === module) {
  setupDatabase()
    .then(() => {
      console.log('✅ Setup completed');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Setup failed:', error);
      process.exit(1);
    });
}

module.exports = { setupDatabase };