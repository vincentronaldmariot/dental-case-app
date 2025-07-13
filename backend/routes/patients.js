const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { verifyPatient } = require('../middleware/auth');

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

module.exports = router; 