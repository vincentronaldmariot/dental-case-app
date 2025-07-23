const express = require('express');
const { body, validationResult } = require('express-validator');
const { query } = require('../config/database');
const { verifyPatient } = require('../middleware/auth');
const { verifyAdmin } = require('../middleware/auth');

const router = express.Router();

// Validation for survey data - more flexible to accommodate different survey formats
const surveyValidation = [
  body('surveyData').isObject().withMessage('Survey data must be an object'),
  body('surveyData.patient_info').optional().isObject().withMessage('Patient info must be an object if provided'),
];

// POST /api/surveys - Submit or update dental survey
router.post('/', async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'] || '';
    const token = authHeader.split(' ')[1];
    if (token === 'kiosk_token') {
      // Allow survey submission for kiosk mode
      req.user = { username: 'kiosk', type: 'kiosk' };
      // Proceed with survey submission logic as kiosk
      // Check validation errors
      const errors = validationResult(req);
      if (!errors.isEmpty()) {
        console.log('Survey validation errors:', errors.array());
        return res.status(400).json({
          error: 'Validation failed',
          details: errors.array()
        });
      }

      const { surveyData } = req.body;
      // Use a special kiosk patient ID for survey submissions
      const patientId = '00000000-0000-0000-0000-000000000000'; // Special kiosk UUID
      
      console.log('Kiosk survey submission for patient:', patientId);
      console.log('Survey data structure:', Object.keys(surveyData));

      // Add submission timestamp
      const completeSurvey = {
        ...surveyData,
        submitted_at: new Date().toISOString(),
        submitted_via: 'kiosk'
      };

      // Check if survey already exists for this kiosk patient
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
      return; // Exit the middleware chain after successful kiosk submission
    }

    // Original authentication and validation logic for non-kiosk requests
    // Check validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('Survey validation errors:', errors.array());
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { surveyData } = req.body;
    const patientId = req.patient.id;
    
    console.log('Survey submission for patient:', patientId);
    console.log('Survey data structure:', Object.keys(surveyData));

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
    console.error('Error details:', error.message);
    res.status(500).json({
      error: 'Failed to submit survey. Please try again.',
      details: error.message
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

// GET /api/admin/surveys/:patientId - Admin fetches any patient's survey
router.get('/admin/surveys/:patientId', verifyAdmin, async (req, res) => {
  try {
    const { patientId } = req.params;
    const { email } = req.query;
    console.log('Admin survey fetch for patientId:', patientId, 'length:', patientId.length, 'email:', email);
    let result = await query(
      `SELECT id, survey_data, completed_at, updated_at FROM dental_surveys WHERE patient_id = $1::uuid ORDER BY updated_at DESC LIMIT 1`,
      [patientId]
    );
    console.log('Survey query result by patientId:', result.rows);
    if (result.rows.length === 0 && email) {
      // Fallback: try by email
      result = await query(
        `SELECT ds.id, ds.survey_data, ds.completed_at, ds.updated_at
         FROM dental_surveys ds
         JOIN patients p ON ds.patient_id = p.id
         WHERE LOWER(p.email) = LOWER($1)
         ORDER BY ds.updated_at DESC LIMIT 1`,
        [email]
      );
      console.log('Survey query result by email:', result.rows);
    }
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'No survey found for this patient' });
    }
    const survey = result.rows[0];
    res.json({
      survey: {
        id: survey.id,
        patientId,
        surveyData: typeof survey.survey_data === 'string' ? JSON.parse(survey.survey_data) : survey.survey_data,
        completedAt: survey.completed_at,
        updatedAt: survey.updated_at
      }
    });
  } catch (error) {
    console.error('Admin fetch survey error:', error);
    res.status(500).json({ error: 'Failed to fetch survey for patient', details: error.message });
  }
});

module.exports = router; 