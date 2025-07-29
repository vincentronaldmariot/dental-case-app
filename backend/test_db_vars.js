console.log('🔍 Testing Database Environment Variables...');
console.log('');

console.log('PGHOST:', process.env.PGHOST);
console.log('PGPORT:', process.env.PGPORT);
console.log('PGDATABASE:', process.env.PGDATABASE);
console.log('PGUSER:', process.env.PGUSER);
console.log('PGPASSWORD:', process.env.PGPASSWORD ? '***SET***' : 'NOT SET');

console.log('');
console.log('DATABASE_URL:', process.env.DATABASE_URL ? '***SET***' : 'NOT SET');

console.log('');
console.log('NODE_ENV:', process.env.NODE_ENV);
console.log('JWT_SECRET:', process.env.JWT_SECRET ? '***SET***' : 'NOT SET');