const express = require('express');
const { body, validationResult } = require('express-validator');
const { verifyToken } = require('../middleware/auth');
const { query } = require('../config/database');
const notificationService = require('../services/notification_service');

const router = express.Router();

// GET /api/notifications/status - Get notification service status
router.get('/status', async (req, res) => {
  try {
    const status = notificationService.getNotificationStatus();
    res.json(status);
  } catch (error) {
    console.error('Get notification status error:', error);
    res.status(500).json({
      error: 'Failed to get notification status'
    });
  }
});

// POST /api/notifications/appointment-reminder - Send appointment reminder
router.post('/appointment-reminder', [
  body('appointment').isObject().withMessage('Appointment data is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { appointment } = req.body;
    
    if (!appointment.patientId) {
      return res.status(400).json({
        error: 'Patient ID is required'
      });
    }

    const result = await notificationService.sendAppointmentReminder(appointment);
    
    res.json({
      id: result.id,
      title: result.title,
      message: result.message,
      emailSent: result.emailSent || false,
      smsSent: result.smsSent || false,
      createdAt: result.createdAt
    });

  } catch (error) {
    console.error('Send appointment reminder error:', error);
    res.status(500).json({
      error: 'Failed to send appointment reminder'
    });
  }
});

// POST /api/notifications/appointment-confirmation - Send appointment confirmation
router.post('/appointment-confirmation', [
  body('appointment').isObject().withMessage('Appointment data is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { appointment } = req.body;
    
    if (!appointment.patientId) {
      return res.status(400).json({
        error: 'Patient ID is required'
      });
    }

    const result = await notificationService.sendAppointmentConfirmation(appointment);
    
    res.json({
      id: result.id,
      title: result.title,
      message: result.message,
      emailSent: result.emailSent || false,
      smsSent: result.smsSent || false,
      createdAt: result.createdAt
    });

  } catch (error) {
    console.error('Send appointment confirmation error:', error);
    res.status(500).json({
      error: 'Failed to send appointment confirmation'
    });
  }
});

// POST /api/notifications/emergency - Send emergency notification
router.post('/emergency', [
  body('patientId').isUUID().withMessage('Valid patient ID is required'),
  body('emergency').isObject().withMessage('Emergency data is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { patientId, emergency } = req.body;

    const result = await notificationService.sendEmergencyNotification(emergency);
    
    res.json({
      id: result.id,
      title: result.title,
      message: result.message,
      emailSent: result.emailSent || false,
      smsSent: result.smsSent || false,
      createdAt: result.createdAt
    });

  } catch (error) {
    console.error('Send emergency notification error:', error);
    res.status(500).json({
      error: 'Failed to send emergency notification'
    });
  }
});

// POST /api/notifications/treatment-update - Send treatment update
router.post('/treatment-update', [
  body('patientId').isUUID().withMessage('Valid patient ID is required'),
  body('treatmentUpdate').isObject().withMessage('Treatment update data is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { patientId, treatmentUpdate } = req.body;

    const result = await notificationService.sendTreatmentUpdate(patientId, treatmentUpdate);
    
    res.json({
      id: result.id,
      title: result.title,
      message: result.message,
      emailSent: result.emailSent || false,
      smsSent: result.smsSent || false,
      createdAt: result.createdAt
    });

  } catch (error) {
    console.error('Send treatment update error:', error);
    res.status(500).json({
      error: 'Failed to send treatment update'
    });
  }
});

// POST /api/notifications/health-tip - Send health tip
router.post('/health-tip', [
  body('patientId').isUUID().withMessage('Valid patient ID is required'),
  body('healthTip').isObject().withMessage('Health tip data is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation failed',
        details: errors.array()
      });
    }

    const { patientId, healthTip } = req.body;

    const result = await notificationService.sendHealthTip(patientId, healthTip);
    
    res.json({
      id: result.id,
      title: result.title,
      message: result.message,
      emailSent: result.emailSent || false,
      smsSent: result.smsSent || false,
      createdAt: result.createdAt
    });

  } catch (error) {
    console.error('Send health tip error:', error);
    res.status(500).json({
      error: 'Failed to send health tip'
    });
  }
});

// GET /api/notifications/:patientId - Get patient notifications
router.get('/:patientId', verifyToken, async (req, res) => {
  try {
    const patientId = req.params.patientId;
    
    // Verify the token belongs to this patient
    if (req.user.id !== patientId) {
      return res.status(403).json({
        error: 'Access denied. You can only view your own notifications.'
      });
    }

    const notifications = await notificationService.getNotifications(patientId);
    
    res.json({
      notifications: notifications.map(notification => ({
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        isRead: notification.isRead,
        emailSent: notification.emailSent || false,
        smsSent: notification.smsSent || false,
        createdAt: notification.createdAt
      }))
    });

  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      error: 'Failed to retrieve notifications'
    });
  }
});

module.exports = router; 