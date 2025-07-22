const { query } = require('./config/database');
const bcrypt = require('bcryptjs');

async function checkPatientPassword() {
  try {
    console.log('🔍 Checking password for vincent@gmail.com...');
    
    // Get the patient's password hash
    const result = await query(`
      SELECT id, first_name, last_name, email, password_hash 
      FROM patients 
      WHERE email = 'vincent@gmail.com'
    `);
    
    if (result.rows.length === 0) {
      console.log('❌ Patient not found');
      return;
    }
    
    const patient = result.rows[0];
    console.log('📋 Patient found:');
    console.log(`   ID: ${patient.id}`);
    console.log(`   Name: ${patient.first_name} ${patient.last_name}`);
    console.log(`   Email: ${patient.email}`);
    console.log(`   Password Hash: ${patient.password_hash}`);
    
    // Test different passwords
    const testPasswords = ['flarelight', 'password123', 'password', 'test123'];
    
    console.log('\n🔐 Testing passwords:');
    for (const password of testPasswords) {
      const isMatch = await bcrypt.compare(password, patient.password_hash);
      console.log(`   "${password}": ${isMatch ? '✅ MATCH' : '❌ NO MATCH'}`);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkPatientPassword(); 