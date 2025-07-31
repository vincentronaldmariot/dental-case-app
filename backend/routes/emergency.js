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
        patient_id, emergency_date, emergency_type, priority, description,
        severity, resolved
      ) VALUES ($1, CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila', $2, $3, $4, $5, false)
      RETURNING id, emergency_date, status
    `, [
      patientId, emergencyType, priority, description, painLevel
    ]);

    const emergency = result.rows[0];

    res.status(201).json({
      message: 'Emergency record submitted successfully',
      emergency: {
        id: emergency.id,
        patientId,
        emergencyDate: emergency.emergency_date,
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
        id, 
        TO_CHAR(emergency_date AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as emergency_date,
        emergency_type, priority, status, description,
        severity, resolved,
        handled_by, resolution, follow_up_required, 
        CASE WHEN resolved_at IS NOT NULL 
          THEN TO_CHAR(resolved_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
          ELSE NULL 
        END as resolved_at,
        emergency_contact, notes, 
        TO_CHAR(created_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
      FROM emergency_records 
      WHERE patient_id = $1
      ORDER BY emergency_date DESC
    `, [patientId]);

    res.json({
      emergencyRecords: result.rows.map(record => ({
        id: record.id,
        patientId,
        emergencyDate: record.emergency_date,
        emergencyType: record.emergency_type,
        priority: record.priority,
        status: record.status,
        description: record.description,
        severity: record.severity,
        resolved: record.resolved,
        handledBy: record.handled_by,
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