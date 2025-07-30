const axios = require('axios');

const BASE_URL = 'https://afp-dental-app-production.up.railway.app';

async function checkRailwayStatus() {
  console.log('🔍 Checking Railway deployment status...');
  console.log(`🌐 URL: ${BASE_URL}`);
  
  // Try different endpoints to see what's working
  const endpoints = [
    '/',
    '/health',
    '/api/health',
    '/api',
    '/api/auth',
    '/api/admin'
  ];
  
  for (const endpoint of endpoints) {
    try {
      console.log(`\n🔍 Testing: ${endpoint}`);
      const response = await axios.get(`${BASE_URL}${endpoint}`, {
        timeout: 5000
      });
      console.log(`✅ ${endpoint} - Status: ${response.status}`);
      if (response.data) {
        console.log(`   Data: ${JSON.stringify(response.data).substring(0, 100)}...`);
      }
    } catch (error) {
      console.log(`❌ ${endpoint} - ${error.message}`);
      if (error.response) {
        console.log(`   Status: ${error.response.status}`);
        console.log(`   Data: ${JSON.stringify(error.response.data).substring(0, 100)}...`);
      }
    }
  }
  
  // Try to check if it's a Railway routing issue
  console.log('\n🔍 Checking if it\'s a Railway routing issue...');
  try {
    const response = await axios.get(`${BASE_URL}`, {
      timeout: 5000,
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });
    console.log('✅ Root endpoint works:', response.status);
    console.log('Response headers:', Object.keys(response.headers));
  } catch (error) {
    console.log('❌ Root endpoint failed:', error.message);
  }
}

checkRailwayStatus(); 