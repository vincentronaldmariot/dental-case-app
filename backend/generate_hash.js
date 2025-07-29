const bcrypt = require('bcryptjs');

async function generateHashes() {
  console.log('🔐 Generating password hashes...\n');
  
  const passwords = [
    { name: 'admin123', password: 'admin123' },
    { name: 'patient123', password: 'patient123' },
    { name: 'vip123', password: 'vip123' }
  ];
  
  for (const item of passwords) {
    const hash = await bcrypt.hash(item.password, 12);
    console.log(`${item.name}:`);
    console.log(`  Password: ${item.password}`);
    console.log(`  Hash: ${hash}`);
    console.log('');
  }
}

generateHashes()
  .then(() => console.log('✅ Hash generation completed'))
  .catch(error => console.error('❌ Error:', error));