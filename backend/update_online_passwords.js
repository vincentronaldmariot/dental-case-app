const { Pool } = require('pg');
const bcrypt = require('bcrypt');

// Use Railway's public database URL
const connectionString = process.env.DATABASE_PUBLIC_URL || 'postgresql://postgres:glfJbkmkHHAAlKQqFzNtkMQjXOPjJthr@ballast.proxy.rlwy.net:27199/railway';

const pool = new Pool({
  connectionString: connectionString,
  ssl: {
    rejectUnauthorized: false
  },
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

async function updateOnlinePasswords() {
  console.log('🔧 Updating passwords on Railway database...');
  
  try {
    // Hash the password
    const passwordHash = await bcrypt.hash('password123', 12);
    console.log('🔐 Password hashed successfully');
    
    // Update all patient passwords
    const result = await pool.query(`
      UPDATE patients 
      SET password_hash = $1
      WHERE email IN (
        'john.doe@test.com',
        'jane.smith@test.com', 
        'vip.person@test.com',
        'viperson1@gmail.com'
      )
    `, [passwordHash]);
    
    console.log(`✅ Updated ${result.rowCount} patient passwords`);
    
    // Verify the update
    const patients = await pool.query(`
      SELECT id, first_name, last_name, email 
      FROM patients 
      WHERE email IN (
        'john.doe@test.com',
        'jane.smith@test.com', 
        'vip.person@test.com',
        'viperson1@gmail.com'
      )
    `);
    
    console.log('\n📋 Patients after password update:');
    patients.rows.forEach((patient, index) => {
      console.log(`${index + 1}. ${patient.first_name} ${patient.last_name} (${patient.email})`);
    });
    
    console.log('\n🎉 All patient passwords have been reset to "password123"');
    console.log('You can now login with any patient email using password: password123');
    
  } catch (error) {
    console.log('❌ Error updating passwords:', error.message);
  } finally {
    await pool.end();
  }
}

updateOnlinePasswords();