const bcrypt = require('bcryptjs');
const { query } = require('./config/database');

async function resetPatientPasswords() {
  try {
    console.log('🔧 Resetting all patient passwords to "password123"...');
    
    // Hash the password
    const saltRounds = parseInt(process.env.BCRYPT_ROUNDS) || 12;
    const hashedPassword = await bcrypt.hash('password123', saltRounds);
    
    console.log('🔐 Password hashed successfully');
    
    // Update all patients with the new password
    const result = await query(`
      UPDATE patients 
      SET password_hash = $1, updated_at = CURRENT_TIMESTAMP
      WHERE password_hash IS NOT NULL
    `, [hashedPassword]);
    
    console.log(`✅ Updated ${result.rowCount} patient passwords`);
    
    // Verify the update by checking a few patients
    const testPatients = await query(`
      SELECT id, first_name, last_name, email 
      FROM patients 
      LIMIT 5
    `);
    
    console.log('\n📋 Sample patients after password reset:');
    testPatients.rows.forEach((patient, index) => {
      console.log(`${index + 1}. ${patient.first_name} ${patient.last_name} (${patient.email})`);
    });
    
    console.log('\n🎉 All patient passwords have been reset to "password123"');
    console.log('You can now login with any patient email using password: password123');
    
  } catch (error) {
    console.error('❌ Error resetting passwords:', error);
  }
}

// Run the reset
resetPatientPasswords(); 