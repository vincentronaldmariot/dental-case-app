const axios = require('axios');

const RAILWAY_TOKEN = process.env.RAILWAY_TOKEN;
const PROJECT_ID = '16a91e92-102e-4f64-8f82-f22524694698';
const SERVICE_ID = '9aeaa294-e90a-46db-a9d3-83d02ab0ff6a';

async function fixRailwayDatabaseConnection() {
  console.log('🔧 Fixing Railway Database Connection...\n');

  if (!RAILWAY_TOKEN) {
    console.log('❌ RAILWAY_TOKEN environment variable not found');
    console.log('Please set RAILWAY_TOKEN with your Railway API token');
    return;
  }

  try {
    // Construct the correct DATABASE_URL
    const DATABASE_URL = 'postgresql://postgres:glfJbkmkHHAAlKQqFzNtkMQjXOPjJthr@ballast.proxy.rlwy.net:27199/railway';
    
    // Construct the correct DATABASE_PUBLIC_URL
    const DATABASE_PUBLIC_URL = 'postgresql://postgres:glfJbkmkHHAAlKQqFzNtkMQjXOPjJthr@ballast.proxy.rlwy.net:27199/railway';

    console.log('📋 Updating Railway environment variables...');
    console.log('🔗 DATABASE_URL:', DATABASE_URL);
    console.log('🔗 DATABASE_PUBLIC_URL:', DATABASE_PUBLIC_URL);

    // Update the environment variables
    const updateResponse = await axios.patch(
      `https://backboard.railway.app/graphql/v2`,
      {
        query: `
          mutation UpdateVariables($serviceId: String!, $variables: [VariableInput!]!) {
            variablesUpdate(serviceId: $serviceId, variables: $variables) {
              id
              name
              value
            }
          }
        `,
        variables: {
          serviceId: SERVICE_ID,
          variables: [
            {
              name: 'DATABASE_URL',
              value: DATABASE_URL
            },
            {
              name: 'DATABASE_PUBLIC_URL',
              value: DATABASE_PUBLIC_URL
            }
          ]
        }
      },
      {
        headers: {
          'Authorization': `Bearer ${RAILWAY_TOKEN}`,
          'Content-Type': 'application/json'
        }
      }
    );

    console.log('✅ Environment variables updated successfully!');
    console.log('🔄 Railway will automatically redeploy with the new variables...');

    // Wait a moment and then test the connection
    console.log('\n⏳ Waiting for deployment to complete...');
    await new Promise(resolve => setTimeout(resolve, 10000));

    console.log('\n🧪 Testing the fixed connection...');
    const testResponse = await axios.get('https://afp-dental-app-production.up.railway.app/api/health');
    console.log('✅ Health check passed:', testResponse.status);

    // Test admin dashboard
    console.log('\n🧪 Testing admin dashboard...');
    const loginResponse = await axios.post('https://afp-dental-app-production.up.railway.app/api/auth/admin/login', {
      username: 'admin',
      password: 'admin123'
    });

    if (loginResponse.status === 200) {
      const token = loginResponse.data.token;
      const headers = {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      };

      const dashboardResponse = await axios.get('https://afp-dental-app-production.up.railway.app/api/admin/dashboard', { headers });
      console.log('✅ Admin dashboard working:', dashboardResponse.status);
    }

    console.log('\n🎉 Database connection should now be fixed!');

  } catch (error) {
    console.error('❌ Error fixing database connection:', error.response?.data || error.message);
    
    if (error.response?.status === 401) {
      console.log('\n🔑 Authentication failed. Please check your RAILWAY_TOKEN');
    }
  }
}

fixRailwayDatabaseConnection(); 