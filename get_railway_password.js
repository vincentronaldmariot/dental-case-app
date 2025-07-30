// Extract password from the DATABASE_URL we saw earlier
const connectionString = 'postgresql://postgres:glfJbkmkHHAAlKQqFzNtkMQjXO PjJthr@postgres.railway.internal:5432/railway';

// Extract password from connection string
const passwordMatch = connectionString.match(/postgresql:\/\/postgres:([^@]+)@/);
if (passwordMatch) {
  const password = passwordMatch[1];
  console.log('🔑 Database Password:', password);
  console.log('\n📋 Now you can use this command:');
  console.log(`PGPASSWORD="${password}" psql -h ballast.proxy.rlwy.net -U postgres -p 27199 -d railway`);
} else {
  console.log('❌ Could not extract password from connection string');
} 