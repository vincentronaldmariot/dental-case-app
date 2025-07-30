const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken');
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
    // Check validation errors first
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      console.log('Survey validation errors:', errors.array());
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { surveyData } = req.body;
    let patientId;
    let isKioskMode = false;

    // Check if this is a kiosk submission
    const authHeader = req.headers['authorization'] || '';
    const token = authHeader.split(' ')[1];
    
    if (token === 'kiosk_token' || !token) {
      // Kiosk mode or no token - use special kiosk patient ID
      patientId = '00000000-0000-0000-0000-000000000000'; // Special kiosk UUID
      isKioskMode = true;
      console.log('Kiosk survey submission for patient:', patientId);
    } else {
      // Try to authenticate as patient
      try {
        // Verify token and get patient data
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        if (decoded.type !== 'patient') {
          return res.status(403).json({
            error: 'Access denied. Patient access required.'
          });
        }
        
        // Get patient data from database
        const result = await query(
          'SELECT id, first_name, last_name, email, phone FROM patients WHERE id = $1',
          [decoded.id]
        );
        
        if (result.rows.length === 0) {
          return res.status(404).json({
            error: 'Patient not found'
          });
        }
        
        patientId = result.rows[0].id;
        console.log('Authenticated survey submission for patient:', patientId);
      } catch (authError) {
        console.error('Authentication error:', authError);
        // If authentication fails, treat as kiosk mode
        patientId = '00000000-0000-0000-0000-000000000000';
        isKioskMode = true;
        console.log('Authentication failed, treating as kiosk mode for patient:', patientId);
      }
    }
    
    console.log('Survey data structure:', Object.keys(surveyData));

    // Add submission timestamp
    const completeSurvey = {
      ...surveyData,
      submitted_at: new Date().toISOString(),
      submitted_via: isKioskMode ? 'kiosk' : 'patient'
    };

    console.log('Attempting to save survey for patient:', patientId);
    console.log('Survey data to save:', JSON.stringify(completeSurvey, null, 2));

    // First, try to create the table if it doesn't exist and ensure all columns exist
    try {
      await query(`
        CREATE TABLE IF NOT EXISTS dental_surveys (
          id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
          patient_id UUID NOT NULL UNIQUE,
          survey_data JSONB NOT NULL,
          completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
      `);
      console.log('✅ dental_surveys table ensured to exist');
      
      // Check and add missing columns if table already existed
      try {
        // Check if updated_at column exists
        const columnExists = await query(`
          SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'dental_surveys' 
            AND column_name = 'updated_at'
          );
        `);
        
        if (!columnExists.rows[0].exists) {
          console.log('🔧 Adding missing updated_at column...');
          await query(`
            ALTER TABLE dental_surveys 
            ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
          `);
          console.log('✅ updated_at column added');
        }
        
        // Check if created_at column exists
        const createdAtExists = await query(`
          SELECT EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'dental_surveys' 
            AND column_name = 'created_at'
          );
        `);
        
        if (!createdAtExists.rows[0].exists) {
          console.log('🔧 Adding missing created_at column...');
          await query(`
            ALTER TABLE dental_surveys 
            ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
          `);
          console.log('✅ created_at column added');
        }
      } catch (columnError) {
        console.error('❌ Failed to add missing columns:', columnError);
      }
    } catch (tableError) {
      console.error('❌ Failed to create table:', tableError);
    }

    // Auto-create kiosk patient if it doesn't exist
    try {
      const existingPatient = await query(
        'SELECT id FROM patients WHERE id = $1',
        ['00000000-0000-0000-0000-000000000000']
      );
      
      if (existingPatient.rows.length === 0) {
        console.log('🔧 Auto-creating kiosk patient...');
        await query(`
          INSERT INTO patients (
            id, first_name, last_name, email, phone, password_hash, 
            date_of_birth, address, emergency_contact, emergency_phone,
            created_at, updated_at
          ) VALUES (
            '00000000-0000-0000-0000-000000000000',
            'Kiosk',
            'User',
            'kiosk@dental.app',
            '00000000000',
            'kiosk_hash',
            '2000-01-01',
            'Kiosk Location',
            'Kiosk Emergency',
            '00000000000',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
          )
        `);
        console.log('✅ Kiosk patient auto-created');
      } else {
        console.log('✅ Kiosk patient already exists');
      }
    } catch (patientError) {
      console.error('❌ Failed to create kiosk patient:', patientError);
    }

    // Use UPSERT to handle both insert and update
    let result;
    try {
      // First try with updated_at column
      result = await query(`
        INSERT INTO dental_surveys (patient_id, survey_data)
        VALUES ($1, $2)
        ON CONFLICT (patient_id) DO UPDATE SET
          survey_data = EXCLUDED.survey_data,
          updated_at = CURRENT_TIMESTAMP
        RETURNING id, completed_at, updated_at
      `, [patientId, JSON.stringify(completeSurvey)]);
      
      console.log('✅ Database query executed successfully with updated_at');
      console.log('Query result:', result);
      console.log('Result rows:', result.rows);
      console.log('Result row count:', result.rowCount);
    } catch (queryError) {
      console.error('❌ Database query failed with updated_at:', queryError);
      
      // If updated_at column doesn't exist, try without it
      if (queryError.message.includes('updated_at')) {
        console.log('🔧 Trying without updated_at column...');
        try {
          result = await query(`
            INSERT INTO dental_surveys (patient_id, survey_data)
            VALUES ($1, $2)
            ON CONFLICT (patient_id) DO UPDATE SET
              survey_data = EXCLUDED.survey_data
            RETURNING id, completed_at
          `, [patientId, JSON.stringify(completeSurvey)]);
          
          console.log('✅ Database query executed successfully without updated_at');
          console.log('Query result:', result);
          console.log('Result rows:', result.rows);
          console.log('Result row count:', result.rowCount);
        } catch (fallbackError) {
          console.error('❌ Fallback database query also failed:', fallbackError);
          return res.status(500).json({
            error: 'Database operation failed',
            details: fallbackError.message
          });
        }
      } else {
        return res.status(500).json({
          error: 'Database operation failed',
          details: queryError.message
        });
      }
    }

    // Check if the query was successful
    if (!result || !result.rows || result.rows.length === 0) {
      console.error('Database query failed - no rows returned');
      console.error('Query result:', result);
      return res.status(500).json({
        error: 'Failed to save survey to database. Please try again.',
        details: 'Database operation did not return expected data'
      });
    }

    const survey = result.rows[0];
    console.log('✅ Survey saved successfully:', survey);

    res.json({
      message: 'Survey submitted successfully',
      survey: {
        id: survey.id,
        patientId,
        completedAt: survey.completed_at,
        updatedAt: survey.updated_at || survey.completed_at
      }
    });

  } catch (error) {
    console.error('Survey submission error:', error);
    console.error('Error details:', error.message);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      error: 'Failed to submit survey. Please try again.',
      details: error.message
    });
  }
});

// GET /api/surveys - Get patient's survey data
router.get('/', async (req, res) => {
  try {
    let patientId;
    
    // Check if this is a kiosk request
    const authHeader = req.headers['authorization'] || '';
    const token = authHeader.split(' ')[1];
    
    if (token === 'kiosk_token' || !token) {
      // Kiosk mode - use special kiosk patient ID
      patientId = '00000000-0000-0000-0000-000000000000';
    } else {
      // Try to authenticate as patient
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        if (decoded.type !== 'patient') {
          return res.status(403).json({
            error: 'Access denied. Patient access required.'
          });
        }
        
        const result = await query(
          'SELECT id, first_name, last_name, email, phone FROM patients WHERE id = $1',
          [decoded.id]
        );
        
        if (result.rows.length === 0) {
          return res.status(404).json({
            error: 'Patient not found'
          });
        }
        
        patientId = result.rows[0].id;
      } catch (authError) {
        // If authentication fails, treat as kiosk mode
        patientId = '00000000-0000-0000-0000-000000000000';
      }
    }

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
router.get('/status', async (req, res) => {
  try {
    let patientId;
    
    // Check if this is a kiosk request
    const authHeader = req.headers['authorization'] || '';
    const token = authHeader.split(' ')[1];
    
    if (token === 'kiosk_token' || !token) {
      // Kiosk mode - use special kiosk patient ID
      patientId = '00000000-0000-0000-0000-000000000000';
    } else {
      // Try to authenticate as patient
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        if (decoded.type !== 'patient') {
          return res.status(403).json({
            error: 'Access denied. Patient access required.'
          });
        }
        
        const result = await query(
          'SELECT id, first_name, last_name, email, phone FROM patients WHERE id = $1',
          [decoded.id]
        );
        
        if (result.rows.length === 0) {
          return res.status(404).json({
            error: 'Patient not found'
          });
        }
        
        patientId = result.rows[0].id;
      } catch (authError) {
        // If authentication fails, treat as kiosk mode
        patientId = '00000000-0000-0000-0000-000000000000';
      }
    }

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
router.delete('/', async (req, res) => {
  try {
    let patientId;
    
    // Check if this is a kiosk request
    const authHeader = req.headers['authorization'] || '';
    const token = authHeader.split(' ')[1];
    
    if (token === 'kiosk_token' || !token) {
      // Kiosk mode - use special kiosk patient ID
      patientId = '00000000-0000-0000-0000-000000000000';
    } else {
      // Try to authenticate as patient
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        if (decoded.type !== 'patient') {
          return res.status(403).json({
            error: 'Access denied. Patient access required.'
          });
        }
        
        const result = await query(
          'SELECT id, first_name, last_name, email, phone FROM patients WHERE id = $1',
          [decoded.id]
        );
        
        if (result.rows.length === 0) {
          return res.status(404).json({
            error: 'Patient not found'
          });
        }
        
        patientId = result.rows[0].id;
      } catch (authError) {
        // If authentication fails, treat as kiosk mode
        patientId = '00000000-0000-0000-0000-000000000000';
      }
    }

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

module.exports = router; // Force redeploy - updated with graceful column handling 