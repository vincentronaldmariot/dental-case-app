const express = require('express');
const { body, validationResult } = require('express-validator');
const emailService = require('../services/email_service');

const router = express.Router();

// Enable CORS for all email routes
router.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// GET /api/email/status - Check email service status
router.get('/status', async (req, res) => {
  try {
    const emailConfigured = !!(process.env.EMAIL_USER && 
                              process.env.EMAIL_PASS && 
                              process.env.EMAIL_HOST);

    res.json({
      configured: emailConfigured,
      emailUser: process.env.EMAIL_USER ? 'Set' : 'Not set',
      emailHost: process.env.EMAIL_HOST ? 'Set' : 'Not set',
      emailPass: process.env.EMAIL_PASS ? 'Set' : 'Not set',
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Email status check error:', error);
    res.status(500).json({
      error: 'Failed to check email status',
      details: error.message
    });
  }
});

// POST /api/email/test - Send test email
router.post('/test', [
  body('to').isEmail().withMessage('Valid email address is required'),
  body('subject').isString().withMessage('Subject is required'),
  body('message').isString().withMessage('Message is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { to, subject, message } = req.body;

    // Check if email service is configured
    const emailConfigured = !!(process.env.EMAIL_USER && 
                              process.env.EMAIL_PASS && 
                              process.env.EMAIL_HOST);

    if (!emailConfigured) {
      return res.status(400).json({
        error: 'Email service not configured',
        details: {
          EMAIL_USER: !!process.env.EMAIL_USER,
          EMAIL_PASS: !!process.env.EMAIL_PASS,
          EMAIL_HOST: !!process.env.EMAIL_HOST
        }
      });
    }

    // Send test email
    const emailResponse = await emailService.sendEmail(to, subject, message);

    res.json({
      success: emailResponse.success,
      messageId: emailResponse.messageId,
      error: emailResponse.error,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Test email error:', error);
    res.status(500).json({
      error: 'Failed to send test email',
      details: error.message
    });
  }
});

// POST /api/email/appointment-confirmation - Send appointment confirmation email
router.post('/appointment-confirmation', [
  body('patientEmail').isEmail().withMessage('Valid patient email is required'),
  body('patientName').isString().withMessage('Patient name is required'),
  body('appointmentDate').isString().withMessage('Appointment date is required'),
  body('timeSlot').isString().withMessage('Time slot is required'),
  body('service').isString().withMessage('Service is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { patientEmail, patientName, appointmentDate, timeSlot, service } = req.body;

    // Check if email service is configured
    const emailConfigured = !!(process.env.EMAIL_USER && 
                              process.env.EMAIL_PASS && 
                              process.env.EMAIL_HOST);

    if (!emailConfigured) {
      return res.status(400).json({
        error: 'Email service not configured'
      });
    }

    // Create appointment data
    const appointmentData = {
      service: service,
      appointment_date: appointmentDate,
      time_slot: timeSlot
    };

    // Create patient data
    const patientData = {
      first_name: patientName.split(' ')[0] || patientName,
      last_name: patientName.split(' ').slice(1).join(' ') || '',
      email: patientEmail
    };

    // Send appointment confirmation email
    const emailResponse = await emailService.sendAppointmentConfirmation(appointmentData, patientData);

    res.json({
      success: emailResponse.success,
      messageId: emailResponse.messageId,
      error: emailResponse.error,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Appointment confirmation email error:', error);
    res.status(500).json({
      error: 'Failed to send appointment confirmation email',
      details: error.message
    });
  }
});

module.exports = router; 