const { query } = require('./config/database');

async function createNotificationsTable() {
  try {
    console.log('Creating notifications table...');
    
    // Create notifications table
    await query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        type VARCHAR(50) NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Create indexes
    await query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_patient_id ON notifications(patient_id)
    `);
    
    await query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type)
    `);
    
    await query(`
      CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at)
    `);
    
    console.log('✅ Notifications table created successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating notifications table:', error);
    process.exit(1);
  }
}

createNotificationsTable(); 