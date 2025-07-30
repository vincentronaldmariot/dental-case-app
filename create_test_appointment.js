const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

async function createTestAppointment() {
  try {
    console.log('🔍 Creating test appointment for approve/reject testing...\n');

    // First, create a test patient
    console.log('📝 Creating test patient...');
    try {
      const patientResponse = await axios.post(`${BASE_URL}/api/auth/register`, {
        firstName: 'Test',
        lastName: 'Patient',
        email: 'testpatient@example.com',
        password: 'testpass123',
        phone: '1234567890',
        dateOfBirth: '1990-01-01',
        address: '123 Test St',
        emergencyContact: 'Emergency Contact',
        emergencyPhone: '0987654321',
        medicalHistory: 'None',
        allergies: 'None',
        classification: 'Military',
        serialNumber: 'TEST123',
        unitAssignment: 'Test Unit'
      });
      console.log('✅ Test patient created successfully');
    } catch (error) {
      if (error.response?.status === 409) {
        console.log('✅ Test patient already exists');
      } else {
        console.log('⚠️  Could not create test patient:', error.response?.data?.error || error.message);
        return;
      }
    }

    // Login as the test patient to create an appointment
    console.log('🔐 Logging in as test patient...');
    const loginResponse = await axios.post(`${BASE_URL}/api/auth/login`, {
      email: 'testpatient@example.com',
      password: 'testpass123'
    });

    const patientToken = loginResponse.data.token;
    const patientHeaders = { Authorization: `Bearer ${patientToken}` };

    console.log('✅ Patient login successful');

    // Create a test appointment
    console.log('📅 Creating test appointment...');
    const appointmentResponse = await axios.post(`${BASE_URL}/api/appointments`, {
      service: 'General Checkup',
      appointmentDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0], // 7 days from now
      timeSlot: '09:00',
      notes: 'Test appointment for approve/reject testing'
    }, { headers: patientHeaders });

    console.log('✅ Test appointment created successfully');
    console.log('📋 Appointment details:', appointmentResponse.data);

    // Wait a moment for the appointment to be processed
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Verify the appointment appears in pending appointments
    console.log('🔍 Verifying appointment appears in pending list...');
    const adminLoginResponse = await axios.post(`${BASE_URL}/api/auth/admin/login`, {
      username: 'admin',
      password: 'admin123'
    });

    const adminToken = adminLoginResponse.data.token;
    const adminHeaders = { Authorization: `Bearer ${adminToken}` };

    const pendingResponse = await axios.get(`${BASE_URL}/api/admin/appointments/pending`, { headers: adminHeaders });

    if (pendingResponse.data.length > 0) {
      console.log('✅ Test appointment found in pending appointments!');
      console.log('📋 Pending appointment details:', JSON.stringify(pendingResponse.data[0], null, 2));
      console.log('\n🎯 Now you can test the approve/reject buttons in the Flutter app!');
    } else {
      console.log('⚠️  Test appointment not found in pending appointments');
    }

  } catch (error) {
    console.error('❌ Failed to create test appointment:', error.response?.data || error.message);
  }
}

createTestAppointment(); 