const { Pool } = require('pg');
const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function testAdminAuthDebug() {
  console.log('🔍 Testing Admin Authentication Debug...\n');

  // Test 1: Direct database connection to admin_users table
  console.log('📊 Test 1: Direct database connection to admin_users...');
  const dbConfig = {
    host: 'ballast.proxy.rlwy.net',
    port: 27199,
    database: 'railway',
    user: 'postgres',
    password: 'glfJbkmkHHAAlKQqFzNtkMQjXOPjJthr',
    ssl: false
  };

  let pool = null;
  try {
    pool = new Pool(dbConfig);
    const client = await pool.connect();
    
    // Check admin_users table
    const adminUsersResult = await client.query('SELECT COUNT(*) as count FROM admin_users');
    console.log('✅ admin_users table exists with', adminUsersResult.rows[0].count, 'records');
    
    // Check specific admin user
    const adminResult = await client.query("SELECT id, username, full_name, role, is_active FROM admin_users WHERE username = 'admin'");
    if (adminResult.rows.length > 0) {
      console.log('✅ Admin user found:', adminResult.rows[0]);
    } else {
      console.log('❌ Admin user not found');
    }
    
    client.release();
  } catch (error) {
    console.log('❌ Database connection error:', error.message);
  } finally {
    if (pool) await pool.end();
  }

  // Test 2: Admin login
  console.log('\n📡 Test 2: Admin login...');
  try {
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    if (loginResponse.status === 200) {
      console.log('✅ Admin login successful');
      console.log('🔑 Token received:', loginResponse.data.token ? 'Yes' : 'No');
      
      const token = loginResponse.data.token;
      const headers = {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      };

      // Test 3: Try a simple admin endpoint
      console.log('\n🔧 Test 3: Testing simple admin endpoint...');
      try {
        const simpleResponse = await axios.get(`${BASE_URL}/api/admin/dashboard`, { headers });
        console.log('✅ Simple admin endpoint:', simpleResponse.status);
        console.log('📊 Response data:', simpleResponse.data);
      } catch (error) {
        console.log('❌ Simple admin endpoint failed:', error.response?.status);
        console.log('📋 Error details:', error.response?.data);
      }

      // Test 4: Try to decode the token
      console.log('\n🔍 Test 4: Token analysis...');
      try {
        const tokenParts = token.split('.');
        if (tokenParts.length === 3) {
          const payload = JSON.parse(Buffer.from(tokenParts[1], 'base64').toString());
          console.log('✅ Token payload:', payload);
        } else {
          console.log('❌ Invalid token format');
        }
      } catch (error) {
        console.log('❌ Token decode error:', error.message);
      }

    } else {
      console.log('❌ Admin login failed:', loginResponse.status);
    }
  } catch (error) {
    console.log('❌ Admin login error:', error.response?.status, error.response?.data);
  }

  console.log('\n📋 Summary:');
  console.log('- If admin_users table has records and admin login works, the issue is in the admin routes');
  console.log('- If admin_users table is empty, we need to create admin users');
  console.log('- If admin login fails, there might be a password issue');
}

testAdminAuthDebug(); 