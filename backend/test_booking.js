const http = require('http');

async function testBookingConflict() {
  try {
    // First, get patient token
    console.log('Getting patient token...');
    const loginData = JSON.stringify({
      email: 'test@example.com',
      password: 'password123'
    });

    const loginOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/auth/login',
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

    console.log('Patient token received:', token.substring(0, 50) + '...');

    // Now try to book an appointment
    console.log('\nTrying to book appointment...');
    // Set appointment date to tomorrow at 10:00 AM local time
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(10, 0, 0, 0); // 10:00 AM local time
    // Print the date being booked for verification
    console.log('Booking for date:', tomorrow.toString());

    const bookingData = JSON.stringify({
      service: 'General Checkup',
      appointmentDate: tomorrow.toISOString(),
      timeSlot: '10:00 AM',
      notes: 'Test booking from script'
    });

    const bookingOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/appointments',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(bookingData)
      }
    };

    const bookingResponse = await new Promise((resolve, reject) => {
      const req = http.request(bookingOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          resolve({ status: res.statusCode, data: data });
        });
      });
      req.on('error', reject);
      req.write(bookingData);
      req.end();
    });

    console.log('Booking response:');
    console.log('Status:', bookingResponse.status);
    console.log('Data:', bookingResponse.data);

    if (bookingResponse.status === 409) {
      console.log('\n❌ 409 Conflict detected! This means:');
      console.log('- The time slot is already taken');
      console.log('- Or there\'s another conflict with the booking');
    } else if (bookingResponse.status === 201) {
      console.log('\n✅ Appointment booked successfully!');
    }

  } catch (error) {
    console.error('Error:', error);
  }
}

testBookingConflict(); 