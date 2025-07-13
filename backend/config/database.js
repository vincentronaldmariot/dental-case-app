const { Pool } = require('pg');

// Database configuration
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'dental_case_db',
  user: process.env.DB_USER || 'dental_user',
  password: process.env.DB_PASSWORD || 'dental_password',
  max: 20, // maximum number of clients in the pool
  idleTimeoutMillis: 30000, // how long a client is allowed to remain idle
  connectionTimeoutMillis: 2000, // how long to wait when connecting a client
};

// Create connection pool
const pool = new Pool(dbConfig);

// Test database connection
async function testConnection() {
  try {
    const client = await pool.connect();
    console.log('📊 Connected to PostgreSQL database successfully');
    
    // Test query
    const result = await client.query('SELECT NOW()');
    console.log('🕒 Database time:', result.rows[0].now);
    
    client.release();
    return true;
  } catch (error) {
    console.error('❌ Database connection failed:', error.message);
    throw error;
  }
}

// Execute query with error handling
async function query(text, params) {
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('📊 Query executed:', { text: text.substring(0, 50), duration, rows: result.rowCount });
    return result;
  } catch (error) {
    console.error('❌ Query error:', { text: text.substring(0, 50), error: error.message });
    throw error;
  }
}

// Get client from pool
async function getClient() {
  return await pool.connect();
}

// Close all connections
async function closePool() {
  await pool.end();
  console.log('🔌 Database pool closed');
}

module.exports = {
  pool,
  query,
  getClient,
  testConnection,
  closePool
}; 