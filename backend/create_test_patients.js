const bcrypt = require('bcrypt');
const { query, testConnection, closePool } = require('./config/database');

async function createTestPatients() {
  console.log('👥 Creating test patients...');
  
  try {
    await testConnection();
    
    // Test patient 1
    const passwordHash1 = await bcrypt.hash('patient123', 12);
    await query(`
      INSERT INTO patients (first_name, last_name, email, phone, password_hash, date_of_birth, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
      ON CONFLICT (email) DO NOTHING
    `, [
      'John', 'Doe', 'john.doe@test.com', '123-456-7890', passwordHash1, '1990-01-15'
    ]);
    
    // Test patient 2
    const passwordHash2 = await bcrypt.hash('patient123', 12);
    await query(`
      INSERT INTO patients (first_name, last_name, email, phone, password_hash, date_of_birth, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
      ON CONFLICT (email) DO NOTHING
    `, [
      'Jane', 'Smith', 'jane.smith@test.com', '234-567-8901', passwordHash2, '1985-05-20'
    ]);
    
    // Test patient 3 (VIP)
    const passwordHash3 = await bcrypt.hash('vip123', 12);
    await query(`
      INSERT INTO patients (first_name, last_name, email, phone, password_hash, date_of_birth, created_at, updated_at)
      VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())
      ON CONFLICT (email) DO NOTHING
    `, [
      'VIP', 'Person', 'vip.person@test.com', '345-678-9012', passwordHash3, '1980-12-10'
    ]);
    
    console.log('✅ Test patients created successfully!');
    console.log('');
    console.log('📋 Test Patient Credentials:');
    console.log('');
    console.log('👤 Patient 1:');
    console.log('   Email: john.doe@test.com');
    console.log('   Password: patient123');
    console.log('');
    console.log('👤 Patient 2:');
    console.log('   Email: jane.smith@test.com');
    console.log('   Password: patient123');
    console.log('');
    console.log('👤 VIP Patient:');
    console.log('   Email: vip.person@test.com');
    console.log('   Password: vip123');
    console.log('');
    console.log('👨‍💼 Admin:');
    console.log('   Username: admin');
    console.log('   Password: admin123');
    
  } catch (error) {
    console.error('❌ Failed to create test patients:', error);
  } finally {
    await closePool();
  }
}

// Run if this script is executed directly
if (require.main === module) {
  createTestPatients();
}

module.exports = { createTestPatients };