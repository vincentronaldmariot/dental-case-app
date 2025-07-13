const express = require('express');
const { query } = require('../config/database');
const { verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/admin/dashboard - Get admin dashboard data
router.get('/dashboard', verifyAdmin, async (req, res) => {
  try {
    // Get statistics
    const [patientsResult, appointmentsResult, surveysResult, emergenciesResult] = await Promise.all([
      query('SELECT COUNT(*) as count FROM patients'),
      query('SELECT COUNT(*) as count, status FROM appointments GROUP BY status'),
      query('SELECT COUNT(*) as count FROM dental_surveys'),
      query('SELECT COUNT(*) as count, status FROM emergency_records GROUP BY status')
    ]);

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
      }, {})
    };

    res.json({
      stats,
      message: 'Dashboard data retrieved successfully'
    });

  } catch (error) {
    console.error('Dashboard error:', error);
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

// GET /api/admin/appointments - Get all appointments
router.get('/appointments', verifyAdmin, async (req, res) => {
  try {
    const { status, limit = 50, offset = 0 } = req.query;

    let queryText = `
      SELECT 
        a.id, a.service, a.appointment_date, a.time_slot, a.doctor_name,
        a.status, a.notes, a.created_at,
        p.first_name, p.last_name, p.email, p.phone
      FROM appointments a
      JOIN patients p ON a.patient_id = p.id
    `;
    const queryParams = [];

    if (status) {
      queryText += ` WHERE a.status = $1`;
      queryParams.push(status);
    }

    queryText += ` ORDER BY a.appointment_date DESC LIMIT $${queryParams.length + 1} OFFSET $${queryParams.length + 2}`;
    queryParams.push(parseInt(limit), parseInt(offset));

    const result = await query(queryText, queryParams);

    res.json({
      appointments: result.rows.map(appointment => ({
        id: appointment.id,
        service: appointment.service,
        appointmentDate: appointment.appointment_date,
        timeSlot: appointment.time_slot,
        doctorName: appointment.doctor_name,
        status: appointment.status,
        notes: appointment.notes,
        patient: {
          name: `${appointment.first_name} ${appointment.last_name}`,
          email: appointment.email,
          phone: appointment.phone
        },
        createdAt: appointment.created_at
      }))
    });

  } catch (error) {
    console.error('Get appointments error:', error);
    res.status(500).json({
      error: 'Failed to retrieve appointments. Please try again.'
    });
  }
});

// PUT /api/admin/appointments/:id/status - Update appointment status
router.put('/appointments/:id/status', verifyAdmin, async (req, res) => {
  try {
    const appointmentId = req.params.id;
    const { status } = req.body;

    if (!['pending', 'scheduled', 'completed', 'cancelled'].includes(status)) {
      return res.status(400).json({
        error: 'Invalid status'
      });
    }

    const result = await query(`
      UPDATE appointments 
      SET status = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING id, status
    `, [status, appointmentId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Appointment not found'
      });
    }

    res.json({
      message: 'Appointment status updated successfully',
      appointment: result.rows[0]
    });

  } catch (error) {
    console.error('Update appointment status error:', error);
    res.status(500).json({
      error: 'Failed to update appointment status. Please try again.'
    });
  }
});

module.exports = router; 