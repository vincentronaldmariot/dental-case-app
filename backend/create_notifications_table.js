const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'dental_case_db',
  password: process.env.DB_PASSWORD || 'your_password',
  port: process.env.DB_PORT || 5432,
});

async function createNotificationsTable() {
  try {
    console.log('🔧 Creating notifications table...');
    
    const createTableQuery = `
      CREATE TABLE IF NOT EXISTS notifications (
          id SERIAL PRIMARY KEY,
          patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
          title VARCHAR(255) NOT NULL,
          message TEXT NOT NULL,
          type VARCHAR(50) NOT NULL,
          is_read BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `;
    
    const createIndexesQuery = `
      CREATE INDEX IF NOT EXISTS idx_notifications_patient_id ON notifications(patient_id);
      CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
      CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
    `;
    
    await pool.query(createTableQuery);
    console.log('✅ Notifications table created successfully');
    
    await pool.query(createIndexesQuery);
    console.log('✅ Indexes created successfully');
    
    // Check if table exists
    const checkTableQuery = `
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'notifications'
      );
    `;
    
    const result = await pool.query(checkTableQuery);
    console.log('📋 Table exists:', result.rows[0].exists);
    
  } catch (error) {
    console.error('❌ Error creating notifications table:', error);
  } finally {
    await pool.end();
  }
}

createNotificationsTable(); 