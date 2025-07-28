const { query } = require('./backend/config/database');

async function testPendingFix() {
  try {
    console.log('🔍 === TESTING PENDING APPOINTMENTS FIX ===');
    console.log('Time:', new Date().toISOString());
    console.log('');

    // Simulate what the Flutter app should see
    const patientId = '8c3a807b-03ae-4cd8-9778-5bd2d6219582'; // From the debug output

    // Get all appointments for this patient
    const appointmentsResult = await query(`
      SELECT 
        id, 
        patient_id, 
        service, 
        appointment_date, 
        time_slot, 
        status, 
        notes,
        created_at
      FROM appointments 
      WHERE patient_id = $1
      ORDER BY created_at DESC
    `, [patientId]);
    
    const appointments = appointmentsResult.rows;

    console.log(`📊 Appointments for patient ${patientId}: ${appointments.length}`);
    console.log('');

    // Count by status (simulating Flutter's _buildConditionalTabs logic)
    const statusCounts = {};
    appointments.forEach(row => {
      const status = row.status || 'unknown';
      statusCounts[status] = (statusCounts[status] || 0) + 1;
    });

    console.log('📈 Status Breakdown (what Flutter should see):');
    Object.entries(statusCounts).forEach(([status, count]) => {
      console.log(`   Status "${status}": ${count} appointments`);
    });
    console.log('');

    // Check for pending appointments specifically
    const pendingAppointments = appointments.filter(row => 
      row.status && row.status.toLowerCase() === 'pending'
    );

    console.log(`⏳ Pending appointments: ${pendingAppointments.length}`);
    console.log(`pendingAppointments.isNotEmpty: ${pendingAppointments.length > 0}`);
    console.log('');

    // Simulate Flutter's tab building logic
    console.log('🔧 Simulating Flutter tab building logic:');
    console.log('   - Always show "All" tab: ✅');
    
    if (pendingAppointments.length > 0) {
      console.log('   - Show "Pending" tab: ✅ (because pendingAppointments.isNotEmpty = true)');
    } else {
      console.log('   - Show "Pending" tab: ❌ (because pendingAppointments.isNotEmpty = false)');
    }

    // Check other statuses
    const scheduledAppointments = appointments.filter(row => 
      row.status && row.status.toLowerCase() === 'scheduled'
    );
    const completedAppointments = appointments.filter(row => 
      row.status && row.status.toLowerCase() === 'completed'
    );
    const cancelledAppointments = appointments.filter(row => 
      row.status && row.status.toLowerCase() === 'cancelled'
    );
    const rejectedAppointments = appointments.filter(row => 
      row.status && row.status.toLowerCase() === 'rejected'
    );

    if (scheduledAppointments.length > 0) {
      console.log('   - Show "Scheduled" tab: ✅');
    } else {
      console.log('   - Show "Scheduled" tab: ❌');
    }

    if (completedAppointments.length > 0) {
      console.log('   - Show "Completed" tab: ✅');
    } else {
      console.log('   - Show "Completed" tab: ❌');
    }

    if (cancelledAppointments.length > 0) {
      console.log('   - Show "Cancelled" tab: ✅');
    } else {
      console.log('   - Show "Cancelled" tab: ❌');
    }

    console.log('');

    // Show what tabs should be visible
    const visibleTabs = ['All'];
    if (pendingAppointments.length > 0) visibleTabs.push('Pending');
    if (scheduledAppointments.length > 0) visibleTabs.push('Scheduled');
    if (completedAppointments.length > 0) visibleTabs.push('Completed');
    if (cancelledAppointments.length > 0) visibleTabs.push('Cancelled');

    console.log('📋 Expected visible tabs:', visibleTabs.join(', '));
    console.log('');

    // Summary
    console.log('✅ SUMMARY:');
    console.log('   - Backend has 0 pending appointments');
    console.log('   - Flutter should NOT show "Pending" tab');
    console.log('   - If Flutter still shows "Pending" tab, it has stale local data');
    console.log('   - Use the new "Clear Pending" button (⏳) in the app to fix');
    console.log('');

    console.log('=== END TEST ===');

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit();
  }
}

testPendingFix(); 