// check_appointments.js
const { query } = require('../backend/config/database');
const { sendNotification } = require('../backend/routes/notifications'); // Adjust if notification logic is elsewhere

async function removeExpiredApprovedAppointments() {
  // Get current time in Asia/Manila
  const now = new Date();
  const phTime = new Date(now.toLocaleString('en-US', { timeZone: 'Asia/Manila' }));
  const phDate = phTime.toISOString().slice(0, 10); // YYYY-MM-DD
  const phHour = phTime.getHours();

  if (phHour < 18) {
    console.log('Not yet 6pm Philippine time. Skipping removal.');
    return;
  }

  // Find all approved appointments for today that are not completed
  const result = await query(`
    SELECT a.id, a.patient_id, a.service, a.appointment_date, a.time_slot, p.email
    FROM appointments a
    JOIN patients p ON a.patient_id = p.id
    WHERE a.status = 'approved'
      AND a.appointment_date::date = $1
  `, [phDate]);

  for (const appt of result.rows) {
    // Mark as removed/cancelled
    await query(`
      UPDATE appointments
      SET status = 'cancelled', updated_at = NOW()
      WHERE id = $1
    `, [appt.id]);

    // Notify the patient
    const message = `Your appointment for ${appt.service} on ${phDate} at ${appt.time_slot} was not completed by the clinic and has been cancelled.`;
    await query(`
      INSERT INTO notifications (patient_id, title, message, type, created_at)
      VALUES ($1, $2, $3, $4, NOW())
    `, [appt.patient_id, 'Appointment Cancelled', message, 'appointment_cancelled']);

    console.log(`Cancelled and notified: ${appt.id} for patient ${appt.patient_id}`);
  }
}

removeExpiredApprovedAppointments()
  .then(() => {
    console.log('Check complete.');
    process.exit(0);
  })
  .catch((err) => {
    console.error('Error in check_appointments:', err);
    process.exit(1);
  }); 