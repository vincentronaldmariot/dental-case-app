const axios = require('axios');

async function testAppointmentBooking() {
  try {
    console.log('🧪 Testing appointment booking process...');
    
    // Step 1: Login as a patient
    console.log('📝 Step 1: Logging in as patient...');
    const loginResponse = await axios.post('http://localhost:3000/api/auth/login', {
      email: 'john.doe@test.com',
      password: 'password123'
    });
    
    const token = loginResponse.data.token;
    const patientId = loginResponse.data.patient.id;
    console.log('✅ Login successful');
    console.log('👤 Patient ID:', patientId);
    
    // Step 2: Book an appointment
    console.log('\n📝 Step 2: Booking an appointment...');
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const appointmentDate = tomorrow.toISOString().split('T')[0]; // YYYY-MM-DD format
    
    const bookingResponse = await axios.post('http://localhost:3000/api/appointments', {
      service: 'Teeth Cleaning',
      appointmentDate: appointmentDate,
      timeSlot: '09:00 AM',
      notes: 'Test appointment booking'
    }, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Appointment booking response:', bookingResponse.data);
    const appointmentId = bookingResponse.data.appointment.id;
    
    // Step 3: Login as admin
    console.log('\n📝 Step 3: Logging in as admin...');
    const adminLoginResponse = await axios.post('http://localhost:3000/api/auth/admin/login', {
      username: 'admin',
      password: 'admin123'
    });
    
    const adminToken = adminLoginResponse.data.token;
    console.log('✅ Admin login successful');
    
    // Step 4: Check pending appointments
    console.log('\n📝 Step 4: Checking pending appointments...');
    const pendingResponse = await axios.get('http://localhost:3000/api/admin/pending-appointments', {
      headers: {
        'Authorization': `Bearer ${adminToken}`,
        'Content-Type': 'application/json'
      }
    });
    
    console.log('✅ Pending appointments response:');
    console.log('📊 Total pending appointments:', pendingResponse.data.length);
    
    if (pendingResponse.data.length > 0) {
      console.log('📋 Pending appointments:');
      pendingResponse.data.forEach((apt, index) => {
        console.log(`  ${index + 1}. ${apt.patient_name} - ${apt.service} - ${apt.booking_date} ${apt.time_slot}`);
      });
      
      // Check if our new appointment is in the list
      const ourAppointment = pendingResponse.data.find(apt => apt.appointment_id === appointmentId);
      if (ourAppointment) {
        console.log('✅ Our new appointment is in the pending list!');
      } else {
        console.log('❌ Our new appointment is NOT in the pending list');
      }
    } else {
      console.log('❌ No pending appointments found');
    }
    
  } catch (error) {
    console.error('❌ Test failed:');
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    } else {
      console.error('Error:', error.message);
    }
  }
}

testAppointmentBooking(); 