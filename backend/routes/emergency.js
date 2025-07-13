const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { verifyPatient, verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// POST /api/emergency - Submit emergency record
router.post('/', verifyPatient, [
  body('emergencyType').notEmpty().withMessage('Emergency type is required'),
  body('priority').isIn(['immediate', 'urgent', 'standard']).withMessage('Valid priority is required'),
  body('description').notEmpty().withMessage('Description is required'),
  body('painLevel').isInt({ min: 0, max: 10 }).withMessage('Pain level must be between 0 and 10'),
  body('symptoms').isArray().withMessage('Symptoms must be an array'),
  body('location').optional().isLength({ max: 100 }).withMessage('Location must not exceed 100 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const {
      emergencyType,
      priority,
      description,
      painLevel,
      symptoms,
      location,
      dutyRelated,
      unitCommand
    } = req.body;
    
    const patientId = req.patient.id;

    const result = await query(`
      INSERT INTO emergency_records (
        patient_id, reported_at, emergency_type, priority, description,
        pain_level, symptoms, location, duty_related, unit_command
      ) VALUES ($1, CURRENT_TIMESTAMP, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING id, reported_at, status
    `, [
      patientId, emergencyType, priority, description,
      painLevel, symptoms, location, dutyRelated || false, unitCommand
    ]);

    const emergency = result.rows[0];

    res.status(201).json({
      message: 'Emergency record submitted successfully',
      emergency: {
        id: emergency.id,
        patientId,
        reportedAt: emergency.reported_at,
        status: emergency.status
      }
    });

  } catch (error) {
    console.error('Emergency submission error:', error);
    res.status(500).json({
      error: 'Failed to submit emergency record. Please try again.'
    });
  }
});

// GET /api/emergency - Get patient's emergency records
router.get('/', verifyPatient, async (req, res) => {
  try {
    const patientId = req.patient.id;

    const result = await query(`
      SELECT 
        id, reported_at, emergency_type, priority, status, description,
        pain_level, symptoms, location, duty_related, unit_command,
        handled_by, first_aid_provided, resolved_at, resolution,
        follow_up_required, emergency_contact, notes, created_at
      FROM emergency_records 
      WHERE patient_id = $1
      ORDER BY reported_at DESC
    `, [patientId]);

    res.json({
      emergencyRecords: result.rows.map(record => ({
        id: record.id,
        patientId,
        reportedAt: record.reported_at,
        emergencyType: record.emergency_type,
        priority: record.priority,
        status: record.status,
        description: record.description,
        painLevel: record.pain_level,
        symptoms: record.symptoms,
        location: record.location,
        dutyRelated: record.duty_related,
        unitCommand: record.unit_command,
        handledBy: record.handled_by,
        firstAidProvided: record.first_aid_provided,
        resolvedAt: record.resolved_at,
        resolution: record.resolution,
        followUpRequired: record.follow_up_required,
        emergencyContact: record.emergency_contact,
        notes: record.notes,
        createdAt: record.created_at
      }))
    });

  } catch (error) {
    console.error('Get emergency records error:', error);
    res.status(500).json({
      error: 'Failed to retrieve emergency records. Please try again.'
    });
  }
});

module.exports = router; 