const express = require('express');
const { body, validationResult } = require('express-validator');
const moment = require('moment');
const { query } = require('../config/database');
const { verifyPatient, verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// Validation for appointment booking
const appointmentValidation = [
  body('service')
    .notEmpty()
    .withMessage('Service is required'),
  body('appointmentDate')
    .isISO8601()
    .withMessage('Valid appointment date is required'),
  body('timeSlot')
    .notEmpty()
    .withMessage('Time slot is required')
];

// POST /api/appointments - Book new appointment
router.post('/', verifyPatient, appointmentValidation, async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { service, appointmentDate, timeSlot, notes } = req.body;
    const patientId = req.patient.id;

    // Validate appointment date is in the future
    // const appointmentMoment = moment(appointmentDate);
    // if (appointmentMoment.isBefore(moment())) {
    //   return res.status(400).json({
    //     error: 'Appointment date must be in the future'
    //   });
    // }

    // Check if time slot is already taken
    // const existingAppointment = await query(`
    //   SELECT id FROM appointments 
    //   WHERE appointment_date = $1 AND time_slot = $2 AND status != 'cancelled'
    // `, [appointmentDate, timeSlot]);

    // if (existingAppointment.rows.length > 0) {
    //   return res.status(409).json({
    //     error: 'This time slot is already booked'
    //   });
    // }

    // Create new appointment
    const result = await query(`
      INSERT INTO appointments (
        patient_id, service, appointment_date, time_slot, notes, status
      ) VALUES ($1, $2, $3::date, $4, $5, 'pending')
      RETURNING id, service, appointment_date, time_slot, status, notes, created_at
    `, [patientId, service, appointmentDate, timeSlot, notes || null]);

    const appointment = result.rows[0];

    res.status(201).json({
      message: 'Appointment booked successfully',
      appointment: {
        id: appointment.id,
        patientId,
        service: appointment.service,
        appointmentDate: appointment.appointment_date,
        timeSlot: appointment.time_slot,
        status: appointment.status,
        notes: appointment.notes,
        createdAt: appointment.created_at
      }
    });

  } catch (error) {
    console.error('Appointment booking error:', error);
    res.status(500).json({
      error: 'Failed to book appointment. Please try again.'
    });
  }
});

// GET /api/appointments - Get patient's appointments
router.get('/', verifyPatient, async (req, res) => {
  try {
    const patientId = req.patient.id;
    const { status, limit = 50, offset = 0 } = req.query;

    let queryText = `
      SELECT id, service, appointment_date, time_slot, status, notes, created_at, updated_at
      FROM appointments 
      WHERE patient_id = $1
    `;
    const queryParams = [patientId];

    // Add status filter if provided
    if (status) {
      queryText += ` AND status = $${queryParams.length + 1}`;
      queryParams.push(status);
    }

    queryText += ` ORDER BY appointment_date DESC LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}`;
    queryParams.push(parseInt(limit), parseInt(offset));

    const result = await query(queryText, queryParams);

    // Get total count for pagination
    let countQuery = 'SELECT COUNT(*) FROM appointments WHERE patient_id = $1';
    const countParams = [patientId];
    
    if (status) {
      countQuery += ' AND status = $2';
      countParams.push(status);
    }

    const countResult = await query(countQuery, countParams);
    const totalCount = parseInt(countResult.rows[0].count);

    res.json({
      appointments: result.rows.map(appointment => ({
        id: appointment.id,
        patientId,
        service: appointment.service,
        appointmentDate: appointment.appointment_date,
        timeSlot: appointment.time_slot,
        status: appointment.status,
        notes: appointment.notes,
        createdAt: appointment.created_at,
        updatedAt: appointment.updated_at
      })),
      pagination: {
        total: totalCount,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: totalCount > parseInt(offset) + parseInt(limit)
      }
    });

  } catch (error) {
    console.error('Get appointments error:', error);
    res.status(500).json({
      error: 'Failed to retrieve appointments. Please try again.'
    });
  }
});

// GET /api/appointments/:id - Get specific appointment
router.get('/:id', verifyPatient, async (req, res) => {
  try {
    const appointmentId = req.params.id;
    const patientId = req.patient.id;

    const result = await query(`
      SELECT id, service, appointment_date, time_slot, status, notes, created_at, updated_at
      FROM appointments 
      WHERE id = $1 AND patient_id = $2
    `, [appointmentId, patientId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found'
      });
    }

    const appointment = result.rows[0];

    res.json({
      appointment: {
        id: appointment.id,
        patientId,
        service: appointment.service,
        appointmentDate: appointment.appointment_date,
        timeSlot: appointment.time_slot,
        status: appointment.status,
        notes: appointment.notes,
        createdAt: appointment.created_at,
        updatedAt: appointment.updated_at
      }
    });

  } catch (error) {
    console.error('Get appointment error:', error);
    res.status(500).json({
      error: 'Failed to retrieve appointment. Please try again.'
    });
  }
});

// PUT /api/appointments/:id - Update appointment (patient can only reschedule pending appointments)
router.put('/:id', verifyPatient, async (req, res) => {
  try {
    const appointmentId = req.params.id;
    const patientId = req.patient.id;
    const { appointmentDate, timeSlot, notes } = req.body;

    // Get current appointment
    const currentResult = await query(`
      SELECT status, appointment_date, time_slot
      FROM appointments 
      WHERE id = $1 AND patient_id = $2
    `, [appointmentId, patientId]);

    if (currentResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found'
      });
    }

    const currentAppointment = currentResult.rows[0];

    // Only allow updates to pending appointments
    if (currentAppointment.status !== 'pending') {
      return res.status(400).json({
        error: 'Only pending appointments can be modified'
      });
    }

    // If changing date/time, validate new slot is available
    if (appointmentDate && timeSlot) {
      const newDateTime = moment(appointmentDate);
      
      if (newDateTime.isBefore(moment())) {
        return res.status(400).json({
          error: 'Appointment date must be in the future'
        });
      }

      // Check if new time slot is available (excluding current appointment)
      const conflictResult = await query(`
        SELECT id FROM appointments 
        WHERE appointment_date = $1 AND time_slot = $2 AND status != 'cancelled' AND id != $3
      `, [appointmentDate, timeSlot, appointmentId]);

      if (conflictResult.rows.length > 0) {
        return res.status(409).json({
          error: 'This time slot is already booked'
        });
      }
    }

    // Update appointment
    const result = await query(`
      UPDATE appointments 
      SET appointment_date = COALESCE($1::date, appointment_date),
          time_slot = COALESCE($2, time_slot),
          notes = COALESCE($3, notes),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $4 AND patient_id = $5
      RETURNING id, service, appointment_date, time_slot, status, notes, updated_at
    `, [appointmentDate, timeSlot, notes, appointmentId, patientId]);

    const appointment = result.rows[0];

    res.json({
      message: 'Appointment updated successfully',
      appointment: {
        id: appointment.id,
        patientId,
        service: appointment.service,
        appointmentDate: appointment.appointment_date,
        timeSlot: appointment.time_slot,
        status: appointment.status,
        notes: appointment.notes,
        updatedAt: appointment.updated_at
      }
    });

  } catch (error) {
    console.error('Update appointment error:', error);
    res.status(500).json({
      error: 'Failed to update appointment. Please try again.'
    });
  }
});

// DELETE /api/appointments/:id - Cancel appointment
router.delete('/:id', verifyPatient, async (req, res) => {
  try {
    const appointmentId = req.params.id;
    const patientId = req.patient.id;

    // Update appointment status to cancelled
    const result = await query(`
      UPDATE appointments 
      SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND patient_id = $2 AND status IN ('pending', 'scheduled')
      RETURNING id, appointment_date, time_slot
    `, [appointmentId, patientId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found or cannot be cancelled'
      });
    }

    res.json({
      message: 'Appointment cancelled successfully',
      appointmentId: result.rows[0].id
    });

  } catch (error) {
    console.error('Cancel appointment error:', error);
    res.status(500).json({
      error: 'Failed to cancel appointment. Please try again.'
    });
  }
});

// GET /api/appointments/available-slots/:date - Get available time slots for a date
router.get('/available-slots/:date', verifyPatient, async (req, res) => {
  try {
    const { date } = req.params;
    
    // Validate date format
    if (!moment(date, 'YYYY-MM-DD', true).isValid()) {
      return res.status(400).json({
        error: 'Invalid date format. Use YYYY-MM-DD'
      });
    }

    // Check if date is in the future
    if (moment(date).isBefore(moment().startOf('day'))) {
      return res.status(400).json({
        error: 'Cannot book appointments for past dates'
      });
    }

    // Define available time slots
    const allTimeSlots = [
      '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
      '14:00', '14:30', '15:00', '15:30', '16:00', '16:30'
    ];

    // Get booked slots for the date
    const result = await query(`
      SELECT time_slot 
      FROM appointments 
      WHERE DATE(appointment_date) = $1 AND status != 'cancelled'
    `, [date]);

    const bookedSlots = result.rows.map(row => row.time_slot);
    const availableSlots = allTimeSlots.filter(slot => !bookedSlots.includes(slot));

    res.json({
      date,
      availableSlots,
      bookedSlots,
      totalSlots: allTimeSlots.length,
      availableCount: availableSlots.length
    });

  } catch (error) {
    console.error('Get available slots error:', error);
    res.status(500).json({
      error: 'Failed to retrieve available slots. Please try again.'
    });
  }
});

module.exports = router; 