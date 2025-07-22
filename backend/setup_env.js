const fs = require('fs');
const path = require('path');

// Environment variables for the backend
const envContent = `# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=dental_case_db
DB_USER=dental_user
DB_PASSWORD=dental_password

# JWT Configuration
JWT_SECRET=dental_case_jwt_secret_key_2024_secure_and_unique
JWT_EXPIRES_IN=7d

# Server Configuration
PORT=3000
NODE_ENV=development

# Security
BCRYPT_ROUNDS=12

# CORS
FRONTEND_URL=http://localhost:3000

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=1000
`;

const envPath = path.join(__dirname, '.env');

try {
  fs.writeFileSync(envPath, envContent);
  console.log('✅ .env file created successfully');
  console.log('📁 Location:', envPath);
  console.log('🔧 Environment variables set up for development');
} catch (error) {
  console.error('❌ Error creating .env file:', error.message);
} 