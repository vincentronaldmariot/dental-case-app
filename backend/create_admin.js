const bcrypt = require('bcrypt');
const { query, testConnection, closePool } = require('./config/database');

async function createAdminUser() {
  console.log('👤 Creating admin user...');
  
  try {
    await testConnection();
    
    // Check if admin user already exists
    const existingAdmin = await query(
      'SELECT id FROM admin_users WHERE username = $1',
      ['admin']
    );
    
    if (existingAdmin.rows.length > 0) {
      console.log('⚠️ Admin user already exists');
      return;
    }
    
    // Hash the password
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash('admin123', saltRounds);
    
    // Insert admin user
    const result = await query(`
      INSERT INTO admin_users (username, password_hash, full_name, role)
      VALUES ($1, $2, $3, $4)
      RETURNING id, username, full_name, role
    `, ['admin', passwordHash, 'System Administrator', 'admin']);
    
    const admin = result.rows[0];
    console.log('✅ Admin user created successfully!');
    console.log(`   ID: ${admin.id}`);
    console.log(`   Username: ${admin.username}`);
    console.log(`   Full Name: ${admin.full_name}`);
    console.log(`   Role: ${admin.role}`);
    console.log('   Password: admin123');
    
  } catch (error) {
    console.error('❌ Failed to create admin user:', error);
  } finally {
    await closePool();
  }
}

// Run if this script is executed directly
if (require.main === module) {
  createAdminUser();
}

module.exports = { createAdminUser }; 