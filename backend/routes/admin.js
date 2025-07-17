const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/admin/dashboard - Get admin dashboard data
router.get('/dashboard', verifyAdmin, async (req, res) => {
  try {
    console.log('🔍 Dashboard request received');
    
    // Get statistics
    const [patientsResult, appointmentsResult, surveysResult, emergenciesResult, todaysAppointmentsResult] = await Promise.all([
      query('SELECT COUNT(*) as count FROM patients'),
      query('SELECT COUNT(*) as count, status FROM appointments GROUP BY status'),
      query('SELECT COUNT(*) as count FROM dental_surveys'),
      query('SELECT COUNT(*) as count, status FROM emergency_records GROUP BY status'),
      // New query for today's scheduled appointments (Philippine Time)
      query(`SELECT COUNT(*) as count FROM appointments WHERE status = 'scheduled' AND appointment_date >= (CURRENT_DATE AT TIME ZONE 'Asia/Manila')::date AND appointment_date < ((CURRENT_DATE AT TIME ZONE 'Asia/Manila')::date + INTERVAL '1 day')`)
    ]);

    console.log('📊 Appointments result:', appointmentsResult.rows);
    
    // Debug: Check what appointment dates exist in the database
    const debugAppointments = await query('SELECT id, appointment_date, status FROM appointments ORDER BY appointment_date DESC LIMIT 5');
    console.log('🔍 Debug - Recent appointments:', debugAppointments.rows);
    
    // Debug: Check what "today" is according to the query
    const todayCheck = await query('SELECT (CURRENT_DATE AT TIME ZONE \'Asia/Manila\')::date as ph_today, CURRENT_DATE as db_today');
    console.log('🔍 Debug - Today dates:', todayCheck.rows[0]);
    
    const stats = {
      totalPatients: parseInt(patientsResult.rows[0].count),
      totalSurveys: parseInt(surveysResult.rows[0].count),
      appointments: appointmentsResult.rows.reduce((acc, row) => {
        acc[row.status] = parseInt(row.count);
        return acc;
      }, {}),
      emergencies: emergenciesResult.rows.reduce((acc, row) => {
        acc[row.status] = parseInt(row.count);
        return acc;
      }, {}),
      // Add today's appointments count
      todaysAppointments: parseInt(todaysAppointmentsResult.rows[0].count)
    };

    console.log('📈 Final stats object:', stats);

    res.json({
      stats,
      message: 'Dashboard data retrieved successfully'
    });

  } catch (error) {
    console.error('❌ Dashboard error:', error);
    res.status(500).json({
      error: 'Failed to retrieve dashboard data. Please try again.'
    });
  }
});

// GET /api/admin/patients - Get all patients
router.get('/patients', verifyAdmin, async (req, res) => {
  try {
    const { limit = 50, offset = 0, search } = req.query;

    let queryText = `
      SELECT 
        id, first_name, last_name, email, phone, classification,
        serial_number, unit_assignment, created_at
      FROM patients
    `;
    const queryParams = [];

    if (search) {
      queryText += ` WHERE first_name ILIKE $1 OR last_name ILIKE $1 OR email ILIKE $1`;
      queryParams.push(`%${search}%`);
    }

    queryText += ` ORDER BY created_at DESC LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}`;
    queryParams.push(parseInt(limit), parseInt(offset));

    const result = await query(queryText, queryParams);

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM patients';
    const countParams = [];
    if (search) {
      countQuery += ' WHERE first_name ILIKE $1 OR last_name ILIKE $1 OR email ILIKE $1';
      countParams.push(`%${search}%`);
    }

    const countResult = await query(countQuery, countParams);
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      patients: result.rows.map(patient => ({
        id: patient.id,
        name: `${patient.first_name} ${patient.last_name}`,
        email: patient.email,
        phone: patient.phone,
        classification: patient.classification,
        serialNumber: patient.serial_number,
        unitAssignment: patient.unit_assignment,
        createdAt: patient.created_at
      })),
      pagination: {
        total: totalCount,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: totalCount > parseInt(offset) + parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Get patients error:', error);
    res.status(500).json({
      error: 'Failed to retrieve patients. Please try again.'
    });
  }
});

// GET /api/admin/appointments - Get all appointments with patient and survey data
router.get('/appointments', verifyAdmin, async (req, res) => {
  try {
    const { status, limit = 50, offset = 0 } = req.query;

    let queryText = `
      SELECT 
        a.id,
        a.service,
        a.appointment_date,
        a.time_slot,
        a.doctor_name,
        a.status,
        a.notes,
        a.created_at,
        a.updated_at,
        p.id as patient_id,
        p.first_name,
        p.last_name,
        p.email,
        p.phone,
        p.classification,
        p.other_classification,
        ds.survey_data,
        ds.completed_at as survey_completed_at
      FROM appointments a
      LEFT JOIN patients p ON a.patient_id = p.id
      LEFT JOIN dental_surveys ds ON p.id = ds.patient_id
    `;
    
    const queryParams = [];

    // Add status filter if provided
    if (status) {
      queryText += ` WHERE a.status = $${queryParams.length + 1}`;
      queryParams.push(status);
    }

    queryText += ` ORDER BY a.created_at DESC LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}`;
    queryParams.push(parseInt(limit), parseInt(offset));

    const result = await query(queryText, queryParams);

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) FROM appointments a';
    const countParams = [];
    
    if (status) {
      countQuery += ' WHERE a.status = $1';
      countParams.push(status);
    }

    const countResult = await query(countQuery, countParams);
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      appointments: result.rows.map(appointment => ({
        id: appointment.id,
        patientId: appointment.patient_id,
        patientName: `${appointment.first_name} ${appointment.last_name}`,
        patientEmail: appointment.email,
        patientPhone: appointment.phone,
        patientClassification: appointment.classification,
        patientOtherClassification: appointment.other_classification,
        service: appointment.service || 'N/A',
        appointmentDate: appointment.appointment_date,
        timeSlot: appointment.time_slot || 'N/A', // Handle null time slots
        doctorName: appointment.doctor_name || 'N/A',
        status: appointment.status,
        notes: appointment.notes,
        createdAt: appointment.created_at,
        updatedAt: appointment.updated_at,
        surveyData: appointment.survey_data,
        surveyCompletedAt: appointment.survey_completed_at
      })),
      pagination: {
        total: totalCount,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: totalCount > parseInt(offset) + parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Admin get appointments error:', error);
    res.status(500).json({
      error: 'Failed to retrieve appointments. Please try again.'
    });
  }
});

// GET /api/admin/appointments/pending - Get pending appointments for review
router.get('/appointments/pending', verifyAdmin, async (req, res) => {
  try {
    const { limit = 20, offset = 0 } = req.query;

    const queryText = `
      SELECT 
        a.id,
        a.service,
        a.appointment_date,
        a.time_slot,
        a.doctor_name,
        a.status,
        a.notes,
        a.created_at,
        a.updated_at,
        p.id as patient_id,
        p.first_name,
        p.last_name,
        p.email,
        p.phone,
        p.classification,
        p.other_classification,
        ds.survey_data,
        ds.completed_at as survey_completed_at
      FROM appointments a
      LEFT JOIN patients p ON a.patient_id = p.id
      LEFT JOIN dental_surveys ds ON p.id = ds.patient_id
      WHERE a.status = 'pending'
      ORDER BY a.created_at ASC
      LIMIT $1 OFFSET $2
    `;

    const result = await query(queryText, [parseInt(limit), parseInt(offset)]);

    // Get total pending count
    const countResult = await query('SELECT COUNT(*) FROM appointments WHERE status = $1', ['pending']);
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      pendingAppointments: result.rows.map(appointment => ({
        id: appointment.id,
        patientId: appointment.patient_id,
        patientName: `${appointment.first_name} ${appointment.last_name}`,
        patientEmail: appointment.email,
        patientPhone: appointment.phone,
        patientClassification: appointment.classification,
        patientOtherClassification: appointment.other_classification,
        service: appointment.service || 'N/A',
        appointmentDate: appointment.appointment_date,
        timeSlot: appointment.time_slot || 'N/A', // Handle null time slots
        doctorName: appointment.doctor_name || 'N/A',
        status: appointment.status,
        notes: appointment.notes,
        createdAt: appointment.created_at,
        updatedAt: appointment.updated_at,
        surveyData: appointment.survey_data,
        surveyCompletedAt: appointment.survey_completed_at,
        hasSurveyData: appointment.survey_data !== null
      })),
      pagination: {
        total: totalCount,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: totalCount > parseInt(offset) + parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Admin get pending appointments error:', error);
    res.status(500).json({
      error: 'Failed to retrieve pending appointments. Please try again.'
    });
  }
});

// GET /api/admin/appointments/:id - Get specific appointment with full details
router.get('/appointments/:id', verifyAdmin, async (req, res) => {
  try {
    const appointmentId = req.params.id;

    const result = await query(`
      SELECT 
        a.id,
        a.service,
        a.appointment_date,
        a.time_slot,
        a.doctor_name,
        a.status,
        a.notes,
        a.created_at,
        a.updated_at,
        p.id as patient_id,
        p.first_name,
        p.last_name,
        p.email,
        p.phone,
        p.date_of_birth,
        p.address,
        p.emergency_contact,
        p.emergency_phone,
        p.medical_history,
        p.allergies,
        p.serial_number,
        p.unit_assignment,
        p.classification,
        p.other_classification,
        ds.survey_data,
        ds.completed_at as survey_completed_at
      FROM appointments a
      LEFT JOIN patients p ON a.patient_id = p.id
      LEFT JOIN dental_surveys ds ON p.id = ds.patient_id
      WHERE a.id = $1
    `, [appointmentId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found'
      });
    }

    const appointment = result.rows[0];

    res.json({
      appointment: {
        id: appointment.id,
        patientId: appointment.patient_id,
        patient: {
          id: appointment.patient_id,
          firstName: appointment.first_name,
          lastName: appointment.last_name,
          email: appointment.email,
          phone: appointment.phone,
          dateOfBirth: appointment.date_of_birth,
          address: appointment.address,
          emergencyContact: appointment.emergency_contact,
          emergencyPhone: appointment.emergency_phone,
          medicalHistory: appointment.medical_history,
          allergies: appointment.allergies,
          serialNumber: appointment.serial_number,
          unitAssignment: appointment.unit_assignment,
          classification: appointment.classification,
          otherClassification: appointment.other_classification
        },
        service: appointment.service || 'N/A',
        appointmentDate: appointment.appointment_date,
        timeSlot: appointment.time_slot || 'N/A', // Handle null time slots
        doctorName: appointment.doctor_name || 'N/A',
        status: appointment.status,
        notes: appointment.notes,
        createdAt: appointment.created_at,
        updatedAt: appointment.updated_at,
        surveyData: appointment.survey_data,
        surveyCompletedAt: appointment.survey_completed_at
      }
    });

  } catch (error) {
    console.error('Admin get appointment error:', error);
    res.status(500).json({
      error: 'Failed to retrieve appointment. Please try again.'
    });
  }
});

// PUT /api/admin/appointments/:id/status - Update appointment status
router.put('/appointments/:id/status', verifyAdmin, [
  body('status').isIn(['pending', 'scheduled', 'completed', 'cancelled', 'missed', 'rescheduled'])
    .withMessage('Invalid status'),
  body('notes').optional().isString().withMessage('Notes must be a string')
], async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const appointmentId = req.params.id;
    const { status, notes } = req.body;

    const result = await query(`
      UPDATE appointments 
      SET status = $1, notes = COALESCE($2, notes), updated_at = CURRENT_TIMESTAMP
      WHERE id = $3
      RETURNING id, status, notes, updated_at
    `, [status, notes, appointmentId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found'
      });
    }

    const appointment = result.rows[0];

    res.json({
      message: 'Appointment status updated successfully',
      appointment: {
        id: appointment.id,
        status: appointment.status,
        notes: appointment.notes,
        updatedAt: appointment.updated_at
      }
    });

  } catch (error) {
    console.error('Admin update appointment status error:', error);
    res.status(500).json({
      error: 'Failed to update appointment status. Please try again.'
    });
  }
});

// GET /api/admin/appointments/statistics - Get appointment statistics
router.get('/appointments/statistics', verifyAdmin, async (req, res) => {
  try {
    const statsResult = await query(`
      SELECT 
        status,
        COUNT(*) as count
      FROM appointments 
      GROUP BY status
    `);

    const statusStats = {};
    statsResult.rows.forEach(row => {
      statusStats[row.status] = parseInt(row.count);
    });

    // Get today's appointments
    const todayResult = await query(`
      SELECT COUNT(*) as count
      FROM appointments 
      WHERE DATE(appointment_date) = CURRENT_DATE
    `);
    const todayAppointments = parseInt(todayResult.rows[0].count);

    // Get pending appointments count
    const pendingCount = statusStats.pending || 0;

    res.json({
      statistics: {
        total: Object.values(statusStats).reduce((sum, count) => sum + count, 0),
        pending: pendingCount,
        scheduled: statusStats.scheduled || 0,
        completed: statusStats.completed || 0,
        cancelled: statusStats.cancelled || 0,
        missed: statusStats.missed || 0,
        rescheduled: statusStats.rescheduled || 0,
        todayAppointments
      }
    });

  } catch (error) {
    console.error('Admin get statistics error:', error);
    res.status(500).json({
      error: 'Failed to retrieve statistics. Please try again.'
    });
  }
});

// POST /api/admin/appointments/:id/reject - Reject appointment and notify patient
router.post('/appointments/:id/reject', verifyAdmin, [
  body('reason').optional().isString().withMessage('Reason must be a string')
], async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const appointmentId = req.params.id;
    const { reason } = req.body;

    // Get appointment details with patient info
    const appointmentResult = await query(`
      SELECT 
        a.id, a.service, a.appointment_date, a.time_slot, a.doctor_name,
        p.first_name, p.last_name, p.email, p.phone
      FROM appointments a
      JOIN patients p ON a.patient_id = p.id
      WHERE a.id = $1 AND a.status = 'pending'
    `, [appointmentId]);

    if (appointmentResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found or not pending'
      });
    }

    const appointment = appointmentResult.rows[0];

    // Update appointment status to rejected
    await query(`
      UPDATE appointments 
      SET status = 'rejected', 
          notes = COALESCE($1, 'Appointment rejected by admin'),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
    `, [reason, appointmentId]);

    // Create notification record for the patient
    console.log('🔔 Starting notification creation...');
    console.log(`Appointment ID: ${appointmentId}`);
    console.log(`Patient Email: ${appointment.email}`);
    
    try {
      // Get patient_id from appointment
      const patientIdResult = await query('SELECT patient_id FROM appointments WHERE id = $1', [appointmentId]);
      console.log('Patient ID query result:', patientIdResult.rows);
      
      if (patientIdResult.rows.length === 0) {
        console.error('❌ No patient_id found for appointment:', appointmentId);
        return;
      }
      
      const patientId = patientIdResult.rows[0].patient_id;
      console.log(`Found patient_id: ${patientId}`);
      
      const notificationMessage = `Your appointment for ${appointment.service} on ${new Date(appointment.appointment_date).toLocaleDateString()} has been rejected.${reason ? ' Reason: ' + reason : ''}`;
      console.log('Notification message:', notificationMessage);
      
      const insertResult = await query(`
        INSERT INTO notifications (patient_id, title, message, type, created_at)
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
        RETURNING id, title, message, type, created_at
      `, [patientId, 'Appointment Rejected', notificationMessage, 'appointment_rejected']);

      // Keep only the 20 most recent notifications for this patient
      await query(`
        DELETE FROM notifications
        WHERE id IN (
          SELECT id FROM notifications
          WHERE patient_id = $1
          ORDER BY created_at DESC
          OFFSET 20
        )
      `, [patientId]);
      
      console.log('✅ Notification created successfully:');
      console.log(JSON.stringify(insertResult.rows[0], null, 2));
      console.log(`✅ Notification created for ${appointment.email}: Appointment rejected`);
    } catch (notificationError) {
      console.error('❌ Failed to create notification:', notificationError);
      console.error('Error details:', notificationError.message);
      console.error('Error stack:', notificationError.stack);
      // Don't fail the whole request if notification creation fails
    }

    res.json({
      message: 'Appointment rejected successfully',
      appointment: {
        id: appointment.id,
        status: 'rejected',
        patientName: `${appointment.first_name} ${appointment.last_name}`,
        patientEmail: appointment.email
      }
    });

  } catch (error) {
    console.error('Admin reject appointment error:', error);
    res.status(500).json({
      error: 'Failed to reject appointment. Please try again.'
    });
  }
});

// POST /api/admin/appointments/:id/approve - Approve appointment and notify patient
router.post('/appointments/:id/approve', verifyAdmin, [
  body('notes').optional().isString().withMessage('Notes must be a string')
], async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const appointmentId = req.params.id;
    const { notes } = req.body;

    // Get appointment details with patient info
    const appointmentResult = await query(`
      SELECT 
        a.id, a.service, a.appointment_date, a.time_slot, a.doctor_name,
        p.first_name, p.last_name, p.email, p.phone
      FROM appointments a
      JOIN patients p ON a.patient_id = p.id
      WHERE a.id = $1 AND a.status = 'pending'
    `, [appointmentId]);

    if (appointmentResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found or not pending'
      });
    }

    const appointment = appointmentResult.rows[0];

    // Update appointment status to scheduled
    await query(`
      UPDATE appointments 
      SET status = 'scheduled', 
          notes = COALESCE($1, notes),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
    `, [notes, appointmentId]);

    // Create notification record for the patient
    console.log('🔔 Starting approval notification creation...');
    console.log(`Appointment ID: ${appointmentId}`);
    console.log(`Patient Email: ${appointment.email}`);
    
    try {
      // Get patient_id from appointment
      const patientIdResult = await query('SELECT patient_id FROM appointments WHERE id = $1', [appointmentId]);
      console.log('Patient ID query result:', patientIdResult.rows);
      
      if (patientIdResult.rows.length === 0) {
        console.error('❌ No patient_id found for appointment:', appointmentId);
        return;
      }
      
      const patientId = patientIdResult.rows[0].patient_id;
      console.log(`Found patient_id: ${patientId}`);
      
      const notificationMessage = `Your appointment for ${appointment.service} on ${new Date(appointment.appointment_date).toLocaleDateString()} at ${appointment.time_slot} has been approved! Please arrive 10 minutes before your scheduled time.`;
      console.log('Notification message:', notificationMessage);
      
      const insertResult = await query(`
        INSERT INTO notifications (patient_id, title, message, type, created_at)
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
        RETURNING id, title, message, type, created_at
      `, [patientId, 'Appointment Approved', notificationMessage, 'appointment_approved']);
      
      // Keep only the 20 most recent notifications for this patient
      await query(`
        DELETE FROM notifications
        WHERE id IN (
          SELECT id FROM notifications
          WHERE patient_id = $1
          ORDER BY created_at DESC
          OFFSET 20
        )
      `, [patientId]);
      
      console.log('✅ Approval notification created successfully:');
      console.log(JSON.stringify(insertResult.rows[0], null, 2));
      console.log(`✅ Notification created for ${appointment.email}: Appointment approved`);
    } catch (notificationError) {
      console.error('❌ Failed to create approval notification:', notificationError);
      console.error('Error details:', notificationError.message);
      console.error('Error stack:', notificationError.stack);
      // Don't fail the whole request if notification creation fails
    }

    res.json({
      message: 'Appointment approved successfully',
      appointment: {
        id: appointment.id,
        status: 'scheduled',
        patientName: `${appointment.first_name} ${appointment.last_name}`,
        patientEmail: appointment.email
      }
    });

  } catch (error) {
    console.error('Admin approve appointment error:', error);
    res.status(500).json({
      error: 'Failed to approve appointment. Please try again.'
    });
  }
});

// GET /api/admin/pending-appointments - Get all pending appointments with patient and survey data
router.get('/pending-appointments', verifyAdmin, async (req, res) => {
  try {
    const result = await query(`
      SELECT 
        a.id AS appointment_id,
        a.service,
        a.appointment_date AS booking_date,
        a.time_slot,
        a.status,
        p.first_name, p.last_name, p.email,
        p.phone,
        p.classification,
        s.survey_data
      FROM appointments a
      JOIN patients p ON a.patient_id = p.id
      LEFT JOIN dental_surveys s ON s.patient_id = p.id
      WHERE a.status = 'pending'
      ORDER BY a.appointment_date ASC
    `);
    
    // Transform the data to handle missing time slots
    const transformedRows = result.rows.map(row => ({
      appointment_id: row.appointment_id,
      service: row.service || 'N/A',
      booking_date: row.booking_date,
      time_slot: row.time_slot || 'N/A', // Handle null time slots
      status: row.status,
      patient_name: `${row.first_name} ${row.last_name}`,
      patient_email: row.email,
      patient_phone: row.phone,
      patient_classification: row.classification,
      survey_data: row.survey_data,
      has_survey_data: row.survey_data !== null
    }));
    
    res.json(transformedRows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch pending appointments' });
  }
});

// PUT /api/admin/update-appointment-datetime - Update appointment date and time
router.put('/update-appointment-datetime', verifyAdmin, [
  body('appointmentId').notEmpty().withMessage('Appointment ID is required'),
  body('newDate').isISO8601().withMessage('Valid date is required'),
  body('newTimeSlot').optional().isString().withMessage('Time slot must be a string')
], async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { appointmentId, newDate, newTimeSlot } = req.body;

    // Check if appointment exists
    const appointmentCheck = await query(
      'SELECT id, status FROM appointments WHERE id = $1',
      [appointmentId]
    );

    if (appointmentCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found'
      });
    }

    const appointment = appointmentCheck.rows[0];

    // Only allow updates for pending appointments
    if (appointment.status !== 'pending') {
      return res.status(400).json({
        error: 'Can only update pending appointments'
      });
    }

    // Check for time slot conflicts only if time slot is provided
    if (newTimeSlot && newTimeSlot !== 'N/A') {
      const conflictCheck = await query(
        'SELECT id FROM appointments WHERE appointment_date = $1 AND time_slot = $2 AND id != $3 AND status IN ($4, $5)',
        [newDate, newTimeSlot, appointmentId, 'pending', 'scheduled']
      );

      if (conflictCheck.rows.length > 0) {
        return res.status(409).json({
          error: 'Time slot is already booked for this date'
        });
      }
    }

    // Update the appointment - only update time_slot if it's not 'N/A'
    const updateQuery = newTimeSlot === 'N/A' || !newTimeSlot
      ? `UPDATE appointments 
         SET appointment_date = $1, updated_at = CURRENT_TIMESTAMP
         WHERE id = $2
         RETURNING id, appointment_date, time_slot`
      : `UPDATE appointments 
         SET appointment_date = $1, time_slot = $2, updated_at = CURRENT_TIMESTAMP
         WHERE id = $3
         RETURNING id, appointment_date, time_slot`;
    
    const updateParams = newTimeSlot === 'N/A' || !newTimeSlot
      ? [newDate, appointmentId]
      : [newDate, newTimeSlot, appointmentId];
    
    const updateResult = await query(updateQuery, updateParams);

    const updatedAppointment = updateResult.rows[0];

    res.json({
      message: 'Appointment date and time updated successfully',
      appointment: {
        id: updatedAppointment.id,
        appointment_date: updatedAppointment.appointment_date,
        time_slot: updatedAppointment.time_slot
      }
    });

  } catch (error) {
    console.error('Error updating appointment date/time:', error);
    res.status(500).json({
      error: 'Failed to update appointment date and time'
    });
  }
});

// PUT /api/admin/update-appointment-service - Update appointment service
router.put('/update-appointment-service', verifyAdmin, [
  body('appointmentId').notEmpty().withMessage('Appointment ID is required'),
  body('newService').notEmpty().withMessage('New service is required')
], async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { appointmentId, newService } = req.body;

    // Check if appointment exists
    const appointmentCheck = await query(
      'SELECT id, status FROM appointments WHERE id = $1',
      [appointmentId]
    );

    if (appointmentCheck.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found'
      });
    }

    const appointment = appointmentCheck.rows[0];

    // Only allow updates for pending appointments
    if (appointment.status !== 'pending') {
      return res.status(400).json({
        error: 'Can only update pending appointments'
      });
    }

    // Update the service
    const updateResult = await query(
      `UPDATE appointments 
       SET service = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2
       RETURNING id, service, updated_at`,
      [newService, appointmentId]
    );

    const updatedAppointment = updateResult.rows[0];

    res.json({
      message: 'Appointment service updated successfully',
      appointment: updatedAppointment
    });
  } catch (error) {
    console.error('Error updating appointment service:', error);
    res.status(500).json({
      error: 'Failed to update appointment service'
    });
  }
});

// POST /api/admin/approve-appointment - Approve an appointment
router.post('/approve-appointment', verifyAdmin, [
  body('appointmentId').notEmpty().withMessage('Appointment ID is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { appointmentId } = req.body;

    // Update appointment status to scheduled
    const result = await query(
      `UPDATE appointments 
       SET status = 'scheduled', updated_at = CURRENT_TIMESTAMP
       WHERE id = $1 AND status = 'pending'
       RETURNING id, status`,
      [appointmentId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found or already processed'
      });
    }

    res.json({
      message: 'Appointment approved successfully',
      appointment: result.rows[0]
    });

  } catch (error) {
    console.error('Error approving appointment:', error);
    res.status(500).json({
      error: 'Failed to approve appointment'
    });
  }
});

// POST /api/admin/reject-appointment - Reject an appointment
router.post('/reject-appointment', verifyAdmin, [
  body('appointmentId').notEmpty().withMessage('Appointment ID is required'),
  body('reason').optional().isString().withMessage('Reason must be a string')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { appointmentId, reason } = req.body;

    // Update appointment status to cancelled
    const result = await query(
      `UPDATE appointments 
       SET status = 'cancelled', notes = $1, updated_at = CURRENT_TIMESTAMP
       WHERE id = $2 AND status = 'pending'
       RETURNING id, status`,
      [reason || 'Rejected by admin', appointmentId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found or already processed'
      });
    }

    res.json({
      message: 'Appointment rejected successfully',
      appointment: result.rows[0]
    });

  } catch (error) {
    console.error('Error rejecting appointment:', error);
    res.status(500).json({
      error: 'Failed to reject appointment'
    });
  }
});

// GET /api/admin/patients/history - Get comprehensive patient history
router.get('/patients/history', verifyAdmin, async (req, res) => {
  try {
    const { limit = 50, offset = 0, search } = req.query;

    // Get all patients with complete data
    let queryText = `
      SELECT 
        p.id,
        p.first_name,
        p.last_name,
        p.email,
        p.phone,
        p.classification,
        p.other_classification,
        p.serial_number,
        p.unit_assignment,
        p.address,
        p.emergency_contact,
        p.emergency_phone,
        p.medical_history,
        p.allergies,
        p.created_at,
        p.updated_at
      FROM patients p
    `;
    const queryParams = [];

    if (search) {
      queryText += ` WHERE p.first_name ILIKE $1 OR p.last_name ILIKE $1 OR p.email ILIKE $1 OR p.serial_number ILIKE $1`;
      queryParams.push(`%${search}%`);
    }

    queryText += ` ORDER BY p.created_at DESC LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}`;
    queryParams.push(parseInt(limit), parseInt(offset));

    const patientsResult = await query(queryText, queryParams);

    // Get comprehensive data for each patient
    const patientsWithHistory = await Promise.all(
      patientsResult.rows.map(async (patient) => {
        // Get appointments for this patient
        const appointmentsResult = await query(`
          SELECT 
            id, service, appointment_date, time_slot, doctor_name, 
            status, notes, created_at, updated_at
          FROM appointments 
          WHERE patient_id = $1 
          ORDER BY created_at DESC
        `, [patient.id]);

        // Get survey for this patient
        const surveyResult = await query(`
          SELECT survey_data, completed_at
          FROM dental_surveys 
          WHERE patient_id = $1
        `, [patient.id]);

        // Get emergency records for this patient
        const emergencyResult = await query(`
          SELECT 
            id, pain_level, symptoms, status, 
            created_at, updated_at
          FROM emergency_records 
          WHERE patient_id = $1 
          ORDER BY created_at DESC
        `, [patient.id]);

        // Get treatment records for this patient
        const treatmentResult = await query(`
          SELECT 
            id, treatment_type, description, treatment_date, 
            doctor_name, notes, created_at
          FROM treatment_records 
          WHERE patient_id = $1 
          ORDER BY treatment_date DESC
        `, [patient.id]);

        return {
          id: patient.id,
          firstName: patient.first_name,
          lastName: patient.last_name,
          fullName: `${patient.first_name} ${patient.last_name}`,
          email: patient.email,
          phone: patient.phone,
          classification: patient.classification,
          otherClassification: patient.other_classification,
          serialNumber: patient.serial_number,
          unitAssignment: patient.unit_assignment,
          address: patient.address,
          emergencyContact: patient.emergency_contact,
          emergencyPhone: patient.emergency_phone,
          medicalHistory: patient.medical_history,
          allergies: patient.allergies,
          createdAt: patient.created_at,
          updatedAt: patient.updated_at,
          
          // Activity history
          appointments: appointmentsResult.rows.map(apt => ({
            id: apt.id,
            service: apt.service,
            appointmentDate: apt.appointment_date,
            timeSlot: apt.time_slot,
            doctorName: apt.doctor_name,
            status: apt.status,
            notes: apt.notes,
            createdAt: apt.created_at,
            updatedAt: apt.updated_at
          })),
          
          survey: surveyResult.rows.length > 0 ? {
            surveyData: surveyResult.rows[0].survey_data,
            completedAt: surveyResult.rows[0].completed_at
          } : null,
          
          emergencyRecords: emergencyResult.rows.map(emergency => ({
            id: emergency.id,
            painLevel: emergency.pain_level,
            symptoms: emergency.symptoms,
            status: emergency.status,
            createdAt: emergency.created_at,
            updatedAt: emergency.updated_at
          })),
          
          treatmentRecords: treatmentResult.rows.map(treatment => ({
            id: treatment.id,
            treatmentType: treatment.treatment_type,
            description: treatment.description,
            datePerformed: treatment.treatment_date,
            doctorName: treatment.doctor_name,
            notes: treatment.notes,
            createdAt: treatment.created_at
          })),
          
          // Summary statistics
          stats: {
            totalAppointments: appointmentsResult.rows.length,
            pendingAppointments: appointmentsResult.rows.filter(apt => apt.status === 'pending').length,
            completedAppointments: appointmentsResult.rows.filter(apt => apt.status === 'completed').length,
            totalEmergencyRecords: emergencyResult.rows.length,
            activeEmergencyRecords: emergencyResult.rows.filter(emergency => emergency.status === 'active').length,
            totalTreatments: treatmentResult.rows.length,
            hasSurvey: surveyResult.rows.length > 0
          }
        };
      })
    );

    // Get total count
    let countQuery = 'SELECT COUNT(*) FROM patients p';
    const countParams = [];
    if (search) {
      countQuery += ' WHERE p.first_name ILIKE $1 OR p.last_name ILIKE $1 OR p.email ILIKE $1 OR p.serial_number ILIKE $1';
      countParams.push(`%${search}%`);
    }

    const countResult = await query(countQuery, countParams);
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      patients: patientsWithHistory,
      pagination: {
        total: totalCount,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: totalCount > parseInt(offset) + parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Get patient history error:', error);
    res.status(500).json({
      error: 'Failed to retrieve patient history. Please try again.'
    });
  }
});

module.exports = router; 