const { Pool } = require('pg');

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

async function checkRailwayAdmin() {
  console.log('🔍 Checking Railway admin users...');
  
  try {
    // Check admin_users table
    const result = await pool.query(`
      SELECT id, username, full_name, role, is_active 
      FROM admin_users
    `);
    
    console.log(`📊 Found ${result.rows.length} admin users:`);
    result.rows.forEach((admin, index) => {
      console.log(`${index + 1}. ID: ${admin.id}, Username: ${admin.username}, Name: ${admin.full_name}, Role: ${admin.role}, Active: ${admin.is_active}`);
    });
    
    if (result.rows.length === 0) {
      console.log('❌ No admin users found in Railway database');
      console.log('💡 This explains why admin endpoints are failing');
    }
    
  } catch (error) {
    console.log('❌ Error checking Railway admin:', error.message);
  } finally {
    await pool.end();
  }
}

checkRailwayAdmin();