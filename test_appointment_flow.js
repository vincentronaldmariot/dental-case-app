const http = require('http');

// At the top of the file, add:
const futureDate = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
const yyyy = futureDate.getFullYear();
const mm = String(futureDate.getMonth() + 1).padStart(2, '0');
const dd = String(futureDate.getDate()).padStart(2, '0');
const futureDateString = `${yyyy}-${mm}-${dd}`;

// Test the complete appointment flow
async function testAppointmentFlow() {
  console.log('🧪 Testing Appointment Flow...\n');

  // Step 1: Login as a patient
  console.log('1. Logging in as patient...');
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

  try {
    const loginResponse = await makeRequest(loginOptions, loginData);
    const loginResult = JSON.parse(loginResponse);
    
    if (loginResult.token) {
      console.log('✅ Patient login successful');
      const token = loginResult.token;
      
      // Step 2: Book an appointment
      console.log('\n2. Booking appointment...');
      const appointmentData = JSON.stringify({
        service: 'General Checkup',
        appointmentDate: futureDateString,
        timeSlot: '02:30 PM',
        notes: 'Test appointment from API'
      });

      const appointmentOptions = {
        hostname: 'localhost',
        port: 3000,
        path: '/api/appointments',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
          'Content-Length': Buffer.byteLength(appointmentData)
        }
      };

      const appointmentResponse = await makeRequest(appointmentOptions, appointmentData);
      const appointmentResult = JSON.parse(appointmentResponse);
      
      if (appointmentResult.message) {
        console.log('✅ Appointment booked successfully');
        console.log(`   Message: ${appointmentResult.message}`);
        
        // Step 3: Check admin pending appointments
        console.log('\n3. Checking admin pending appointments...');
        const adminOptions = {
          hostname: 'localhost',
          port: 3000,
          path: '/api/admin/appointments/pending',
          method: 'GET',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer admin_token' // This would need proper admin auth
          }
        };

        try {
          const adminResponse = await makeRequest(adminOptions);
          const adminResult = JSON.parse(adminResponse);
          
          if (adminResult.pendingAppointments) {
            console.log('✅ Admin can see pending appointments');
            console.log(`   Found ${adminResult.pendingAppointments.length} pending appointments`);
            
            // Show the first pending appointment
            if (adminResult.pendingAppointments.length > 0) {
              const firstAppointment = adminResult.pendingAppointments[0];
              console.log(`   Latest: ${firstAppointment.patientName} - ${firstAppointment.service} on ${firstAppointment.appointmentDate}`);
            }
          } else {
            console.log('❌ Admin cannot see pending appointments');
            console.log('   Response:', adminResponse);
          }
        } catch (adminError) {
          console.log('⚠️ Admin endpoint error (expected without proper admin auth):', adminError.message);
        }
        
      } else {
        console.log('❌ Appointment booking failed');
        console.log('   Response:', appointmentResponse);
      }
      
    } else {
      console.log('❌ Patient login failed');
      console.log('   Response:', loginResponse);
    }
    
  } catch (error) {
    console.log('❌ Test failed:', error.message);
  }
}

function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(responseData);
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${responseData}`));
        }
      });
    });
    
    req.on('error', (error) => {
      reject(error);
    });
    
    if (data) {
      req.write(data);
    }
    
    req.end();
  });
}

// Run the test
testAppointmentFlow(); 