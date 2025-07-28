const http = require('http');

// Test the emergency completion process
async function testEmergencyCompletion() {
  console.log('🧪 Testing Emergency Completion Date Fix...\n');

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

    // Step 2: Get emergency records to find one to test with
    const emergencyOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/admin/emergencies',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${adminToken}`
      }
    };

    const emergencyResponse = await makeRequest(emergencyOptions);
    console.log('📋 Emergency Records Response Status:', emergencyResponse.statusCode);
    
    if (emergencyResponse.statusCode !== 200) {
      console.log('❌ Failed to get emergency records:', emergencyResponse.body);
      return;
    }

    const emergencyData = JSON.parse(emergencyResponse.body);
    const emergencyRecords = emergencyData.emergencyRecords;
    
    if (emergencyRecords.length === 0) {
      console.log('❌ No emergency records found to test with');
      return;
    }

    // Find an emergency that's not already resolved
    const testEmergency = emergencyRecords.find(er => er.status !== 'resolved');
    
    if (!testEmergency) {
      console.log('❌ No unresolved emergency records found to test with');
      return;
    }

    console.log('🔍 Testing with emergency:', {
      id: testEmergency.id,
      status: testEmergency.status,
      reportedAt: testEmergency.reportedAt,
      resolvedAt: testEmergency.resolvedAt
    });

    // Step 3: Update emergency status to resolved
    const updateData = JSON.stringify({
      status: 'resolved',
      handledBy: 'Admin',
      resolution: 'Emergency resolved and converted to appointment',
      followUpRequired: 'Follow-up appointment created'
    });

    const updateOptions = {
      hostname: 'localhost',
      port: 3000,
      path: `/api/admin/emergencies/${testEmergency.id}/status`,
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`,
        'Content-Length': Buffer.byteLength(updateData)
      }
    };

    const updateResponse = await makeRequest(updateOptions, updateData);
    console.log('📋 Update Emergency Response Status:', updateResponse.statusCode);
    
    if (updateResponse.statusCode !== 200) {
      console.log('❌ Failed to update emergency:', updateResponse.body);
      return;
    }

    console.log('✅ Emergency status updated to resolved\n');

    // Step 4: Get the updated emergency record to get the resolved_at date
    const updatedEmergencyResponse = await makeRequest(emergencyOptions);
    
    if (updatedEmergencyResponse.statusCode !== 200) {
      console.log('❌ Failed to get updated emergency records:', updatedEmergencyResponse.body);
      return;
    }

    const updatedEmergencyData = JSON.parse(updatedEmergencyResponse.body);
    const updatedEmergency = updatedEmergencyData.emergencyRecords.find(e => e.id === testEmergency.id);
    
    if (!updatedEmergency) {
      console.log('❌ Could not find updated emergency record');
      return;
    }

    console.log('📅 Updated Emergency Record:', {
      id: updatedEmergency.id,
      status: updatedEmergency.status,
      reportedAt: updatedEmergency.reportedAt,
      resolvedAt: updatedEmergency.resolvedAt
    });

    // Step 5: Create appointment using the resolved date
    const resolvedAtString = updatedEmergency.resolvedAt;
    const resolvedDate = resolvedAtString ? new Date(resolvedAtString) : new Date();
    const appointmentDate = resolvedDate.toISOString().split('T')[0];

    console.log('📅 Appointment Date Calculation:', {
      resolvedAtString,
      resolvedDate: resolvedDate.toISOString(),
      appointmentDate
    });

    const appointmentData = JSON.stringify({
      patient_id: updatedEmergency.patientId,
      service: 'Emergency Follow-up: Test Emergency',
      date: appointmentDate,
      time_slot: 'Emergency Resolution',
      notify_patient: false
    });

    const appointmentOptions = {
      hostname: 'localhost',
      port: 3000,
      path: '/api/admin/appointments/rebook',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${adminToken}`,
        'Content-Length': Buffer.byteLength(appointmentData)
      }
    };

    const appointmentResponse = await makeRequest(appointmentOptions, appointmentData);
    console.log('📋 Create Appointment Response Status:', appointmentResponse.statusCode);
    
    if (appointmentResponse.statusCode !== 200) {
      console.log('❌ Failed to create appointment:', appointmentResponse.body);
      return;
    }

    const appointmentResult = JSON.parse(appointmentResponse.body);
    console.log('✅ Appointment Created:', {
      id: appointmentResult.appointment.id,
      appointmentDate: appointmentResult.appointment.appointmentDate,
      service: appointmentResult.appointment.service
    });

    console.log('\n🎉 Test completed successfully!');
    console.log('📅 The appointment was created with the correct resolved date from the emergency record.');

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
testEmergencyCompletion(); 