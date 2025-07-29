const { Pool } = require('pg');

let useMemoryDB = false;
let pool = null;

// Enhanced SSL configuration for Railway
const getSSLConfig = () => {
  if (process.env.NODE_ENV !== 'production') {
    return false;
  }
  
  // For Railway, use a simpler SSL configuration
  return {
    rejectUnauthorized: false
  };
};

// Use DATABASE_PUBLIC_URL if available (for external connections), otherwise use DATABASE_URL
const dbConfig = (process.env.DATABASE_PUBLIC_URL || process.env.DATABASE_URL) ? {
  connectionString: process.env.DATABASE_PUBLIC_URL || process.env.DATABASE_URL,
  ssl: getSSLConfig(),
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 30000, // Increased timeout for SSL
  query_timeout: 30000,
  statement_timeout: 30000
} : {
  host: process.env.PGHOST || process.env.DB_HOST || 'localhost',
  port: process.env.PGPORT || process.env.DB_PORT || 5432,
  database: process.env.PGDATABASE || process.env.DB_NAME || 'dental_case_db',
  user: process.env.PGUSER || process.env.DB_USER || 'dental_user',
  password: process.env.PGPASSWORD || process.env.DB_PASSWORD || 'dental_password',
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 30000, // Increased timeout for SSL
  ssl: getSSLConfig(),
};

console.log('🗄️ Database config:', {
  host: dbConfig.host || 'DATABASE_URL',
  port: dbConfig.port || 'DATABASE_URL',
  database: dbConfig.database || 'DATABASE_URL',
  user: dbConfig.user || 'DATABASE_URL',
  ssl: dbConfig.ssl ? 'enabled' : 'disabled',
  connectionTimeoutMillis: dbConfig.connectionTimeoutMillis,
  hasDatabaseUrl: !!(process.env.DATABASE_PUBLIC_URL || process.env.DATABASE_URL),
  usingPublicUrl: !!process.env.DATABASE_PUBLIC_URL
});

// Try to create PostgreSQL pool
try {
  pool = new Pool(dbConfig);
  console.log('✅ PostgreSQL pool created');
} catch (error) {
  console.log('⚠️ Failed to create PostgreSQL pool, using in-memory database');
  useMemoryDB = true;
}

// Test database connection
async function testConnection() {
  if (useMemoryDB) {
    const memoryDB = require('./memory_db');
    return await memoryDB.testConnection();
  }
  
  try {
    const client = await pool.connect();
    const result = await client.query('SELECT NOW() as current_time');
    console.log('📊 Connected to PostgreSQL database successfully');
    console.log('🕒 Database time:', result.rows[0].current_time);
    client.release();
    return true;
  } catch (error) {
    console.error('❌ PostgreSQL connection failed, switching to in-memory database:', error.message);
    useMemoryDB = true;
    const memoryDB = require('./memory_db');
    return await memoryDB.testConnection();
  }
}

// Execute a query with error handling
async function query(text, params) {
  if (useMemoryDB) {
    const memoryDB = require('./memory_db');
    return await memoryDB.query(text, params);
  }
  
  const start = Date.now();
  try {
    const result = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('📊 Query executed:', {
      text: text.substring(0, 50) + (text.length > 50 ? '...' : ''),
      duration,
      rows: result.rowCount
    });
    return result;
  } catch (error) {
    console.error('❌ Query error:', {
      text: text.substring(0, 50) + (text.length > 50 ? '...' : ''),
      error: error.message
    });
    throw error;
  }
}

// Close the pool
async function closePool() {
  if (useMemoryDB) {
    const memoryDB = require('./memory_db');
    return await memoryDB.closePool();
  }
  
  try {
    await pool.end();
    console.log('🔌 Database pool closed');
  } catch (error) {
    console.error('❌ Error closing pool:', error);
  }
}

module.exports = {
  pool,
  query,
  testConnection,
  closePool
}; 