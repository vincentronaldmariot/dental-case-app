const { query } = require('./config/database');
const bcrypt = require('bcryptjs');

async function createAdminUsersTable() {
  try {
    console.log('Creating admin_users table...');

    // Create admin_users table
    await query(`
      CREATE TABLE IF NOT EXISTS admin_users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        full_name VARCHAR(100) NOT NULL,
        email VARCHAR(100) UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        role VARCHAR(20) DEFAULT 'admin',
        is_active BOOLEAN DEFAULT true,
        last_login TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);

    console.log('Admin users table created successfully');

    // Create index for username
    await query(`
      CREATE INDEX IF NOT EXISTS idx_admin_users_username ON admin_users(username)
    `);

    // Create index for email (only if email column exists)
    try {
      await query(`
        CREATE INDEX IF NOT EXISTS idx_admin_users_email ON admin_users(email)
      `);
    } catch (error) {
      console.log('Email index creation skipped (email column may not exist)');
    }

    console.log('Indexes created successfully');

    // Check if default admin exists
    const existingAdmin = await query(
      'SELECT id FROM admin_users WHERE username = $1',
      ['admin']
    );

    if (existingAdmin.rows.length === 0) {
      console.log('Creating default admin user...');

      // Hash password for default admin
      const saltRounds = 12;
      const hashedPassword = await bcrypt.hash('admin123', saltRounds);

      // Insert default admin
      await query(`
        INSERT INTO admin_users (username, full_name, email, password_hash, role)
        VALUES ($1, $2, $3, $4, $5)
      `, [
        'admin',
        'System Administrator',
        'admin@dental-clinic.mil',
        hashedPassword,
        'admin'
      ]);

      console.log('Default admin user created successfully');
      console.log('Username: admin');
      console.log('Password: admin123');
    } else {
      console.log('Default admin user already exists');
    }

    console.log('Admin users setup completed successfully');

  } catch (error) {
    console.error('Error creating admin users table:', error);
    process.exit(1);
  }
}

// Run the setup
createAdminUsersTable(); 