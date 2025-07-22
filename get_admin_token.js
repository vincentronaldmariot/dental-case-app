const axios = require('axios');

async function getAdminToken() {
  try {
    const response = await axios.post('http://localhost:3000/api/auth/admin/login', {
      username: 'admin',
      password: 'admin123'
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    console.log('Fresh admin token:', response.data.token);
    return response.data.token;
  } catch (error) {
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else if (error.request) {
      console.error('No response received. Server might not be running.');
      console.error('Request:', error.request);
    } else {
      console.error('Error:', error.message);
    }
  }
}

getAdminToken(); 