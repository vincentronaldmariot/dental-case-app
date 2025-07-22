const axios = require('axios');

const adminToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImJlNTBjOTAxLTdlZWQtNDIyOC05NzExLTk5OWIwOGEwZTcyZCIsInVzZXJuYW1lIjoiYWRtaW4iLCJ0eXBlIjoiYWRtaW4iLCJpYXQiOjE3NTMwNzY1MzQsImV4cCI6MTc1MzY4MTMzNH0.lxNtKMDK3BHgEr_1a4sO-feulD41Hfp-X9PJoWnmQMA';

async function testPendingAppointments() {
  try {
    console.log('🔍 Testing pending appointments API...');
    
    const response = await axios.get('http://localhost:3000/api/admin/pending-appointments', {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });

    console.log('✅ API Response Status:', response.status);
    console.log('📊 Number of pending appointments:', response.data.length);
    
    if (response.data.length > 0) {
      console.log('📋 Sample appointment data:');
      const sample = response.data[0];
      console.log({
        appointment_id: sample.appointment_id,
        patient_name: sample.patient_name,
        service: sample.service,
        booking_date: sample.booking_date,
        time_slot: sample.time_slot,
        patient_classification: sample.patient_classification,
        patient_unit_assignment: sample.patient_unit_assignment,
        patient_serial_number: sample.patient_serial_number,
        has_survey_data: sample.has_survey_data
      });
    } else {
      console.log('ℹ️ No pending appointments found');
    }

  } catch (error) {
    console.error('❌ Error testing pending appointments:');
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

// Run the test
testPendingAppointments(); 