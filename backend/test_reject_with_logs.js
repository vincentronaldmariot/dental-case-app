const http = require('http');

async function testRejectWithLogs() {
  try {
    // First, get admin token
    console.log('Getting admin token...');
    const loginData = JSON.stringify({
      username: 'admin',
      password: 'admin123'
    });

    const loginOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/admin/login',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(loginData)
      }
    };

    const token = await new Promise((resolve, reject) => {
      const req = http.request(loginOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            resolve(response.token);
          } catch (e) {
            reject(e);
          }
        });
      });
      req.on('error', reject);
      req.write(loginData);
      req.end();
    });

    console.log('Token received:', token);

    // Get pending appointments first
    console.log('\nGetting pending appointments...');
    const pendingOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/admin/pending-appointments',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };

    const pendingResponse = await new Promise((resolve, reject) => {
      const req = http.request(pendingOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            resolve({ status: res.statusCode, data: response });
          } catch (e) {
            reject(e);
          }
        });
      });
      req.on('error', reject);
      req.end();
    });

    console.log('Pending appointments count:', pendingResponse.data.length);
    
    if (pendingResponse.data.length === 0) {
      console.log('No pending appointments to test with');
      return;
    }

    // Test reject the first pending appointment
    const appointmentToReject = pendingResponse.data[0];
    console.log(`\nTesting reject for appointment: ${appointmentToReject.appointment_id}`);

    const rejectData = JSON.stringify({
      reason: 'Test rejection - appointment time conflict'
    });

    const rejectOptions = {
      hostname: 'localhost',
      port: 3000,
      path: `/api/admin/appointments/${appointmentToReject.appointment_id}/reject`,
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(rejectData)
      }
    };

    console.log('Making reject request to:', rejectOptions.path);
    console.log('Request data:', rejectData);

    const rejectResponse = await new Promise((resolve, reject) => {
      const req = http.request(rejectOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          try {
            const response = JSON.parse(data);
            resolve({ status: res.statusCode, data: response });
          } catch (e) {
            reject(e);
          }
        });
      });
      req.on('error', reject);
      req.write(rejectData);
      req.end();
    });

    console.log('Reject response:');
    console.log('Status:', rejectResponse.status);
    console.log('Data:', JSON.stringify(rejectResponse.data, null, 2));

    // Wait a moment for any async operations
    console.log('\nWaiting 2 seconds for async operations...');
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Check notifications count
    console.log('\nChecking notifications in database...');
    const { query } = require('./config/database');
    const countResult = await query('SELECT COUNT(*) as count FROM notifications');
    console.log(`Total notifications: ${countResult.rows[0].count}`);

    if (countResult.rows[0].count > 0) {
      const latestResult = await query(`
        SELECT * FROM notifications 
        ORDER BY created_at DESC 
        LIMIT 1
      `);
      console.log('Latest notification:');
      console.log(JSON.stringify(latestResult.rows[0], null, 2));
    }

  } catch (error) {
    console.error('Error:', error);
  }
}

testRejectWithLogs(); 