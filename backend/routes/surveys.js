const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { verifyPatient } = require('../middleware/auth');

const router = express.Router();

// Validation for survey data
const surveyValidation = [
  body('surveyData').isObject().withMessage('Survey data must be an object'),
  body('surveyData.patient_info').isObject().withMessage('Patient info is required'),
  body('surveyData.tooth_conditions').isObject().withMessage('Tooth conditions are required'),
  body('surveyData.tartar_level').notEmpty().withMessage('Tartar level is required'),
  body('surveyData.tooth_sensitive').isBoolean().withMessage('Tooth sensitivity must be boolean'),
  body('surveyData.damaged_fillings').isObject().withMessage('Damaged fillings data is required'),
  body('surveyData.need_dentures').isBoolean().withMessage('Need dentures must be boolean'),
  body('surveyData.has_missing_teeth').isBoolean().withMessage('Has missing teeth must be boolean')
];

// POST /api/surveys - Submit or update dental survey
router.post('/', verifyPatient, surveyValidation, async (req, res) => {
  try {
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { surveyData } = req.body;
    const patientId = req.patient.id;

    // Add submission timestamp
    const completeSurvey = {
      ...surveyData,
      submitted_at: new Date().toISOString()
    };

    // Check if survey already exists for this patient
    const existingResult = await query(
      'SELECT id FROM dental_surveys WHERE patient_id = $1',
      [patientId]
    );

    let result;
    if (existingResult.rows.length > 0) {
      // Update existing survey
      result = await query(`
        UPDATE dental_surveys 
        SET survey_data = $1, updated_at = CURRENT_TIMESTAMP
        WHERE patient_id = $2
        RETURNING id, completed_at, updated_at
      `, [JSON.stringify(completeSurvey), patientId]);
    } else {
      // Create new survey
      result = await query(`
        INSERT INTO dental_surveys (patient_id, survey_data)
        VALUES ($1, $2)
        RETURNING id, completed_at, updated_at
      `, [patientId, JSON.stringify(completeSurvey)]);
    }

    const survey = result.rows[0];

    res.json({
      message: existingResult.rows.length > 0 ? 'Survey updated successfully' : 'Survey submitted successfully',
      survey: {
        id: survey.id,
        patientId,
        completedAt: survey.completed_at,
        updatedAt: survey.updated_at
      }
    });

  } catch (error) {
    console.error('Survey submission error:', error);
    res.status(500).json({
      error: 'Failed to submit survey. Please try again.'
    });
  }
});

// GET /api/surveys - Get patient's survey data
router.get('/', verifyPatient, async (req, res) => {
  try {
    const patientId = req.patient.id;

    const result = await query(`
      SELECT id, survey_data, completed_at, updated_at
      FROM dental_surveys 
      WHERE patient_id = $1
      ORDER BY updated_at DESC
      LIMIT 1
    `, [patientId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'No survey found for this patient'
      });
    }

    const survey = result.rows[0];

    res.json({
      survey: {
        id: survey.id,
        patientId,
        surveyData: survey.survey_data,
        completedAt: survey.completed_at,
        updatedAt: survey.updated_at
      }
    });

  } catch (error) {
    console.error('Survey retrieval error:', error);
    res.status(500).json({
      error: 'Failed to retrieve survey. Please try again.'
    });
  }
});

// GET /api/surveys/status - Check if patient has completed survey
router.get('/status', verifyPatient, async (req, res) => {
  try {
    const patientId = req.patient.id;

    const result = await query(`
      SELECT id, completed_at, updated_at
      FROM dental_surveys 
      WHERE patient_id = $1
      ORDER BY updated_at DESC
      LIMIT 1
    `, [patientId]);

    const hasCompletedSurvey = result.rows.length > 0;

    res.json({
      hasCompletedSurvey,
      surveyInfo: hasCompletedSurvey ? {
        id: result.rows[0].id,
        completedAt: result.rows[0].completed_at,
        updatedAt: result.rows[0].updated_at
      } : null
    });

  } catch (error) {
    console.error('Survey status error:', error);
    res.status(500).json({
      error: 'Failed to check survey status. Please try again.'
    });
  }
});

// DELETE /api/surveys - Delete patient's survey (for testing)
router.delete('/', verifyPatient, async (req, res) => {
  try {
    const patientId = req.patient.id;

    const result = await query(
      'DELETE FROM dental_surveys WHERE patient_id = $1 RETURNING id',
      [patientId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'No survey found to delete'
      });
    }

    res.json({
      message: 'Survey deleted successfully',
      deletedSurveyId: result.rows[0].id
    });

  } catch (error) {
    console.error('Survey deletion error:', error);
    res.status(500).json({
      error: 'Failed to delete survey. Please try again.'
    });
  }
});

module.exports = router; 