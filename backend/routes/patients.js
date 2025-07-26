const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { verifyPatient } = require('../middleware/auth');
const { verifyToken } = require('../middleware/auth'); // Added verifyToken

const router = express.Router();

// GET /api/patients/profile - Get patient profile
router.get('/profile', verifyPatient, async (req, res) => {
  try {
    const patientId = req.patient.id;

    const result = await query(`
      SELECT 
        id, first_name, last_name, email, phone, date_of_birth,
        address, emergency_contact, emergency_phone, medical_history, allergies,
        serial_number, unit_assignment, classification, other_classification,
        created_at, updated_at
      FROM patients 
      WHERE id = $1
    `, [patientId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Patient profile not found'
      });
    }

    const patient = result.rows[0];

    res.json({
      profile: {
        id: patient.id,
        firstName: patient.first_name,
        lastName: patient.last_name,
        email: patient.email,
        phone: patient.phone,
        dateOfBirth: patient.date_of_birth,
        address: patient.address,
        emergencyContact: patient.emergency_contact,
        emergencyPhone: patient.emergency_phone,
        medicalHistory: patient.medical_history,
        allergies: patient.allergies,
        serialNumber: patient.serial_number,
        unitAssignment: patient.unit_assignment,
        classification: patient.classification,
        otherClassification: patient.other_classification,
        createdAt: patient.created_at,
        updatedAt: patient.updated_at
      }
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      error: 'Failed to retrieve profile. Please try again.'
    });
  }
});

// PUT /api/patients/profile - Update patient profile
router.put('/profile', verifyPatient, [
  body('firstName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('First name must be between 2 and 100 characters'),
  body('lastName')
    .optional()
    .trim()
    .isLength({ min: 2, max: 100 })
    .withMessage('Last name must be between 2 and 100 characters'),
  body('phone')
    .optional()
    .isMobilePhone()
    .withMessage('Please provide a valid phone number'),
  body('address')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Address must not exceed 500 characters'),
  body('emergencyContact')
    .optional()
    .isLength({ max: 100 })
    .withMessage('Emergency contact must not exceed 100 characters'),
  body('emergencyPhone')
    .optional()
    .isMobilePhone()
    .withMessage('Please provide a valid emergency phone number'),
  body('medicalHistory')
    .optional()
    .isLength({ max: 1000 })
    .withMessage('Medical history must not exceed 1000 characters'),
  body('allergies')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Allergies must not exceed 500 characters')
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

    const patientId = req.patient.id;
    const {
      firstName,
      lastName,
      phone,
      address,
      emergencyContact,
      emergencyPhone,
      medicalHistory,
      allergies
    } = req.body;

    // Update only provided fields
    const updateFields = [];
    const updateValues = [];
    let paramCount = 1;

    if (firstName !== undefined) {
      updateFields.push(`first_name = $${paramCount++}`);
      updateValues.push(firstName);
    }
    if (lastName !== undefined) {
      updateFields.push(`last_name = $${paramCount++}`);
      updateValues.push(lastName);
    }
    if (phone !== undefined) {
      updateFields.push(`phone = $${paramCount++}`);
      updateValues.push(phone);
    }
    if (address !== undefined) {
      updateFields.push(`address = $${paramCount++}`);
      updateValues.push(address);
    }
    if (emergencyContact !== undefined) {
      updateFields.push(`emergency_contact = $${paramCount++}`);
      updateValues.push(emergencyContact);
    }
    if (emergencyPhone !== undefined) {
      updateFields.push(`emergency_phone = $${paramCount++}`);
      updateValues.push(emergencyPhone);
    }
    if (medicalHistory !== undefined) {
      updateFields.push(`medical_history = $${paramCount++}`);
      updateValues.push(medicalHistory);
    }
    if (allergies !== undefined) {
      updateFields.push(`allergies = $${paramCount++}`);
      updateValues.push(allergies);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        error: 'No fields to update'
      });
    }

    updateFields.push(`updated_at = CURRENT_TIMESTAMP`);
    updateValues.push(patientId);

    const result = await query(`
      UPDATE patients 
      SET ${updateFields.join(', ')}
      WHERE id = $${paramCount}
      RETURNING 
        id, first_name, last_name, email, phone, date_of_birth,
        address, emergency_contact, emergency_phone, medical_history, allergies,
        serial_number, unit_assignment, classification, other_classification,
        updated_at
    `, updateValues);

    const patient = result.rows[0];

    res.json({
      message: 'Profile updated successfully',
      profile: {
        id: patient.id,
        firstName: patient.first_name,
        lastName: patient.last_name,
        email: patient.email,
        phone: patient.phone,
        dateOfBirth: patient.date_of_birth,
        address: patient.address,
        emergencyContact: patient.emergency_contact,
        emergencyPhone: patient.emergency_phone,
        medicalHistory: patient.medical_history,
        allergies: patient.allergies,
        serialNumber: patient.serial_number,
        unitAssignment: patient.unit_assignment,
        classification: patient.classification,
        otherClassification: patient.other_classification,
        updatedAt: patient.updated_at
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      error: 'Failed to update profile. Please try again.'
    });
  }
});

// GET /api/patients/:id/notifications - Get patient notifications
router.get('/:id/notifications', verifyToken, async (req, res) => {
  try {
    const patientId = req.params.id;
    
    // Verify the token belongs to this patient
    if (req.user.id !== patientId) {
      return res.status(403).json({
        error: 'Access denied. You can only view your own notifications.'
      });
    }

    const result = await query(`
      SELECT id, title, message, type, is_read, created_at
      FROM notifications 
      WHERE patient_id = $1
      ORDER BY created_at DESC
      LIMIT 50
    `, [patientId]);

    res.json({
      notifications: result.rows.map(notification => ({
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        isRead: notification.is_read,
        createdAt: notification.created_at
      }))
    });

  } catch (error) {
    console.error('Get patient notifications error:', error);
    res.status(500).json({
      error: 'Failed to retrieve notifications. Please try again.'
    });
  }
});

// PUT /api/patients/:id/notifications/:notificationId/read - Mark notification as read
router.put('/:id/notifications/:notificationId/read', verifyToken, async (req, res) => {
  try {
    const patientId = req.params.id;
    const notificationId = req.params.notificationId;
    
    // Verify the token belongs to this patient
    if (req.user.id !== patientId) {
      return res.status(403).json({
        error: 'Access denied. You can only update your own notifications.'
      });
    }

    const result = await query(`
      UPDATE notifications 
      SET is_read = true, updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND patient_id = $2
      RETURNING id, is_read
    `, [notificationId, patientId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Notification not found'
      });
    }

    res.json({
      message: 'Notification marked as read',
      notification: {
        id: result.rows[0].id,
        isRead: result.rows[0].is_read
      }
    });

  } catch (error) {
    console.error('Mark notification read error:', error);
    res.status(500).json({
      error: 'Failed to update notification. Please try again.'
    });
  }
});

// GET /api/patients/:id/notifications/unread-count - Get unread notifications count
router.get('/:id/notifications/unread-count', verifyToken, async (req, res) => {
  try {
    const patientId = req.params.id;
    
    // Verify the token belongs to this patient
    if (req.user.id !== patientId) {
      return res.status(403).json({
        error: 'Access denied. You can only view your own notifications.'
      });
    }

    const result = await query(`
      SELECT COUNT(*) as count
      FROM notifications 
      WHERE patient_id = $1 AND is_read = false
    `, [patientId]);

    res.json({
      unreadCount: parseInt(result.rows[0].count)
    });

  } catch (error) {
    console.error('Get unread count error:', error);
    res.status(500).json({
      error: 'Failed to retrieve unread count. Please try again.'
    });
  }
});

// GET /api/patients/:id/history - Get comprehensive patient history
router.get('/:id/history', verifyToken, async (req, res) => {
  try {
    const patientId = req.params.id;
    
    // Verify the token belongs to this patient
    if (req.user.id !== patientId) {
      return res.status(403).json({
        error: 'Access denied. You can only view your own history.'
      });
    }

    // Get patient's survey data
    const surveyResult = await query(`
      SELECT id, survey_data, completed_at, updated_at
      FROM dental_surveys 
      WHERE patient_id = $1
      ORDER BY updated_at DESC
      LIMIT 1
    `, [patientId]);

    // Get patient's appointments
    const appointmentsResult = await query(`
      SELECT id, service, date, time_slot, status, notes, created_at
      FROM appointments 
      WHERE patient_id = $1
      ORDER BY date DESC
      LIMIT 20
    `, [patientId]);

    // Get patient's treatment records (if they exist in database)
    const treatmentResult = await query(`
      SELECT id, treatment_type, description, treatment_date, 
             procedures, notes, prescription, created_at
      FROM treatment_records 
      WHERE patient_id = $1
      ORDER BY treatment_date DESC
      LIMIT 20
    `, [patientId]);

    // Get patient's emergency records
    const emergencyResult = await query(`
      SELECT id, type, priority, status, description, reported_at, 
             pain_level, symptoms, location, handled_by, resolved_at, resolution
      FROM emergency_records 
      WHERE patient_id = $1
      ORDER BY reported_at DESC
      LIMIT 20
    `, [patientId]);

    const history = {
      patientId,
      survey: surveyResult.rows.length > 0 ? {
        id: surveyResult.rows[0].id,
        surveyData: surveyResult.rows[0].survey_data,
        completedAt: surveyResult.rows[0].completed_at,
        updatedAt: surveyResult.rows[0].updated_at
      } : null,
      appointments: appointmentsResult.rows.map(apt => ({
        id: apt.id,
        service: apt.service,
        date: apt.date,
        timeSlot: apt.time_slot,
        status: apt.status,
        notes: apt.notes,
        createdAt: apt.created_at
      })),
      treatments: treatmentResult.rows.map(tr => ({
        id: tr.id,
        treatmentType: tr.treatment_type,
        description: tr.description,
        treatmentDate: tr.treatment_date,
        procedures: tr.procedures,
        notes: tr.notes,
        prescription: tr.prescription,
        createdAt: tr.created_at
      })),
      emergencies: emergencyResult.rows.map(er => ({
        id: er.id,
        type: er.type,
        priority: er.priority,
        status: er.status,
        description: er.description,
        reportedAt: er.reported_at,
        painLevel: er.pain_level,
        symptoms: er.symptoms,
        location: er.location,
        handledBy: er.handled_by,
        resolvedAt: er.resolved_at,
        resolution: er.resolution
      }))
    };

    res.json({
      history
    });

  } catch (error) {
    console.error('Get patient history error:', error);
    res.status(500).json({
      error: 'Failed to retrieve patient history. Please try again.'
    });
  }
});

module.exports = router; 