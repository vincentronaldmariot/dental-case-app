const axios = require('axios');

// Railway API configuration
const RAILWAY_TOKEN = process.env.RAILWAY_TOKEN;
const PROJECT_ID = process.env.RAILWAY_PROJECT_ID;
const SERVICE_ID = process.env.RAILWAY_SERVICE_ID;

async function forceRailwayRestart() {
  if (!RAILWAY_TOKEN || !PROJECT_ID || !SERVICE_ID) {
    console.log('❌ Missing Railway environment variables:');
    console.log('   RAILWAY_TOKEN:', RAILWAY_TOKEN ? 'Set' : 'Missing');
    console.log('   RAILWAY_PROJECT_ID:', PROJECT_ID ? 'Set' : 'Missing');
    console.log('   RAILWAY_SERVICE_ID:', SERVICE_ID ? 'Set' : 'Missing');
    console.log('\n📋 To set these variables:');
    console.log('   1. Go to Railway Dashboard');
    console.log('   2. Select your project');
    console.log('   3. Go to Variables tab');
    console.log('   4. Add these environment variables');
    return;
  }

  try {
    console.log('🔄 Forcing Railway restart...');
    
    // Update environment variables to trigger restart
    const timestamp = new Date().toISOString();
    const response = await axios.patch(
      `https://backboard.railway.app/graphql/v2`,
      {
        query: `
          mutation UpdateVariables($serviceId: String!, $variables: [VariableInput!]!) {
            serviceUpdateVariables(serviceId: $serviceId, variables: $variables) {
              id
            }
          }
        `,
        variables: {
          serviceId: SERVICE_ID,
          variables: [
            {
              name: 'FORCE_RESTART',
              value: timestamp
            },
            {
              name: 'RESTART_TIMESTAMP',
              value: timestamp
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

    console.log('✅ Railway restart triggered successfully');
    console.log('⏳ Wait 2-3 minutes for deployment to complete...');
    
  } catch (error) {
    console.error('❌ Failed to force Railway restart:', error.message);
    if (error.response) {
      console.error('Response:', error.response.data);
    }
  }
}

forceRailwayRestart(); 