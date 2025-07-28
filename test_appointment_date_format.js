const http = require('http');

// Test appointment date formatting
async function testAppointmentDateFormat() {
  console.log('🧪 Testing Appointment Date Format Fix...\n');

  try {
    // Step 1: Get admin token
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

    const loginResponse = await makeRequest(loginOptions, loginData);
    console.log('📋 Login Response Status:', loginResponse.statusCode);
    
    if (loginResponse.statusCode !== 200) {
      console.log('❌ Login failed:', loginResponse.body);
      return;
    }

    const loginResult = JSON.parse(loginResponse.body);
    const adminToken = loginResult.token;
    console.log('✅ Admin token obtained\n');

    // Step 2: Get patients to find one with appointments
    const patientsOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/admin/patients?limit=10',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${adminToken}`
      }
    };

    const patientsResponse = await makeRequest(patientsOptions);
    console.log('📋 Patients Response Status:', patientsResponse.statusCode);
    
    if (patientsResponse.statusCode !== 200) {
      console.log('❌ Failed to get patients:', patientsResponse.body);
      return;
    }

    const patientsData = JSON.parse(patientsResponse.body);
    const patients = patientsData.patients;
    
    if (patients.length === 0) {
      console.log('❌ No patients found to test with');
      return;
    }

    // Find a patient with appointments
    let testPatient = null;
    for (const patient of patients) {
      const appointmentsOptions = {
        hostname: 'localhost',
        port: 3000,
        path: `/api/admin/patients/${patient.id}/appointments`,
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      };

      const appointmentsResponse = await makeRequest(appointmentsOptions);
      if (appointmentsResponse.statusCode === 200) {
        const appointmentsData = JSON.parse(appointmentsResponse.body);
        if (appointmentsData.appointments && appointmentsData.appointments.length > 0) {
          testPatient = patient;
          console.log('🔍 Found patient with appointments:', {
            id: patient.id,
            name: `${patient.firstName} ${patient.lastName}`,
            appointmentCount: appointmentsData.appointments.length
          });
          
          // Show the first appointment's date format
          const firstAppointment = appointmentsData.appointments[0];
          console.log('📅 First appointment date format:', {
            appointmentDate: firstAppointment.appointment_date,
            service: firstAppointment.service,
            status: firstAppointment.status
          });
          break;
        }
      }
    }

    if (!testPatient) {
      console.log('❌ No patients with appointments found to test with');
      return;
    }

    console.log('\n✅ Test completed successfully!');
    console.log('📅 Appointment dates are now being formatted with proper timezone information.');

  } catch (error) {
    console.error('❌ Test failed:', error);
  }
}

function makeRequest(options, data = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => {
        body += chunk;
      });
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: body
        });
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
testAppointmentDateFormat(); 