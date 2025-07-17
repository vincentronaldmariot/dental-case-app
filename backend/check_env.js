require('dotenv').config();

console.log('🔍 Checking Environment Variables...\n');

const requiredVars = [
  'JWT_SECRET',
  'DB_HOST',
  'DB_PORT', 
  'DB_NAME',
  'DB_USER',
  'DB_PASSWORD'
];

const optionalVars = [
  'BCRYPT_ROUNDS',
  'JWT_EXPIRES_IN',
  'NODE_ENV',
  'FRONTEND_URL'
];

console.log('Required Variables:');
requiredVars.forEach(varName => {
  const value = process.env[varName];
  if (value) {
    console.log(`✅ ${varName}: ${varName.includes('PASSWORD') ? '***SET***' : value}`);
  } else {
    console.log(`❌ ${varName}: NOT SET`);
  }
});

console.log('\nOptional Variables:');
optionalVars.forEach(varName => {
  const value = process.env[varName];
  if (value) {
    console.log(`✅ ${varName}: ${value}`);
  } else {
    console.log(`ℹ️  ${varName}: NOT SET (using default)`);
  }
});

console.log('\nCurrent Environment:');
console.log(`NODE_ENV: ${process.env.NODE_ENV || 'development'}`);
console.log(`PORT: ${process.env.PORT || 3000}`);

// Check if JWT_SECRET is set (critical for auth)
if (!process.env.JWT_SECRET) {
  console.log('\n⚠️  WARNING: JWT_SECRET is not set! Authentication will fail.');
  console.log('Please set JWT_SECRET in your .env file or environment variables.');
} else {
  console.log('\n✅ JWT_SECRET is set - authentication should work.');
} 