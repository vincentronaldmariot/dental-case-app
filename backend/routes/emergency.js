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
        pain_level, status
      ) VALUES ($1, CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Manila', $2, $3, $4, $5, 'reported')
      RETURNING id, reported_at, status
    `, [
      patientId, emergencyType, priority, description, painLevel
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
        id, 
        TO_CHAR(reported_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as reported_at,
        emergency_type, priority, status, description,
        pain_level, 
        handled_by, resolution, follow_up_required, 
        CASE WHEN resolved_at IS NOT NULL 
          THEN TO_CHAR(resolved_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
          ELSE NULL 
        END as resolved_at,
        emergency_contact, notes, 
        TO_CHAR(created_at AT TIME ZONE 'Asia/Manila', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') as created_at
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

// GET /api/emergency/admin - Get all emergency records for admin
router.get('/admin', verifyAdmin, async (req, res) => {
  try {
    console.log('🔍 Admin fetching all emergency records...');
    
    const queryText = `
      SELECT 
        er.id, 
        er.patient_id, 
        er.reported_at, 
        er.emergency_type, 
        er.description,
        COALESCE(er.status, 'reported') as status,
        COALESCE(er.priority, 'standard') as priority,
        COALESCE(er.pain_level, 0) as pain_level,
        er.handled_by, 
        er.resolution, 
        er.follow_up_required, 
        er.resolved_at,
        er.emergency_contact, 
        er.notes, 
        er.created_at,
        p.first_name, 
        p.last_name, 
        p.email, 
        p.phone
      FROM emergency_records er
      LEFT JOIN patients p ON er.patient_id = p.id
      ORDER BY er.reported_at DESC
    `;

    const result = await query(queryText);
    console.log(`📊 Found ${result.rows.length} emergency records`);

    const emergencyRecords = result.rows.map(record => ({
      id: record.id,
      patientId: record.patient_id,
      patientName: `${record.first_name || ''} ${record.last_name || ''}`.trim() || 'Unknown Patient',
      patientEmail: record.email || '',
      patientPhone: record.phone || '',
      reportedAt: record.reported_at,
      emergencyType: record.emergency_type || 'unknown',
      description: record.description || '',
      painLevel: record.pain_level || 0,
      status: record.status || 'reported',
      priority: record.priority || 'standard',
      handledBy: record.handled_by || '',
      resolution: record.resolution || '',
      followUpRequired: record.follow_up_required || '',
      resolvedAt: record.resolved_at,
      emergencyContact: record.emergency_contact || '',
      notes: record.notes || '',
      resolved: record.status === 'resolved',
      createdAt: record.created_at
    }));

    console.log('✅ Emergency records processed successfully');
    res.json(emergencyRecords);

  } catch (error) {
    console.error('❌ Error fetching emergency records:', error);
    res.status(500).json({
      error: 'Failed to retrieve emergency records. Please try again.',
      details: error.message
    });
  }
});

// PUT /api/emergency/admin/:id/status - Update emergency status for admin
router.put('/admin/:id/status', verifyAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes } = req.body;
    
    console.log(`🔄 Admin updating emergency ${id} status to ${status}`);
    
    const queryText = `
      UPDATE emergency_records 
      SET status = $1, notes = COALESCE($2, notes), updated_at = NOW()
      WHERE id = $3
      RETURNING *
    `;
    
    const result = await query(queryText, [status, notes, id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Emergency record not found' });
    }
    
    console.log('✅ Emergency status updated successfully');
    res.json({ 
      message: 'Emergency status updated successfully',
      emergency: result.rows[0]
    });
    
  } catch (error) {
    console.error('❌ Error updating emergency status:', error);
    res.status(500).json({
      error: 'Failed to update emergency status. Please try again.',
      details: error.message
    });
  }
});

// POST /api/emergency/:id/notify - Send emergency notification with SMS
router.post('/:id/notify', verifyAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { message } = req.body;

    console.log(`📱 Admin sending emergency notification for emergency ${id}`);

    // Get emergency record
    const emergencyResult = await query(`
      SELECT 
        er.id, 
        er.patient_id, 
        er.emergency_type, 
        er.status,
        er.description,
        er.notes,
        p.first_name,
        p.last_name,
        p.phone
      FROM emergency_records er
      LEFT JOIN patients p ON er.patient_id = p.id
      WHERE er.id = $1
    `, [id]);

    if (emergencyResult.rows.length === 0) {
      return res.status(404).json({ error: 'Emergency record not found' });
    }

    const emergency = emergencyResult.rows[0];

    // Create notification in database
    const notificationResult = await query(`
      INSERT INTO notifications (patient_id, title, message, type, created_at)
      VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
      RETURNING id, title, message, type, is_read, created_at
    `, [
      emergency.patient_id,
      'Emergency Case Update',
      `Your emergency dental case (${emergency.emergency_type}) has been ${emergency.status}. ${message ? `Notes: ${message}` : ''}`,
      'emergency'
    ]);

    const notification = notificationResult.rows[0];

    // Check if SMS service is configured
    const smsConfigured = !!(process.env.TWILIO_ACCOUNT_SID && 
                            process.env.TWILIO_AUTH_TOKEN && 
                            process.env.TWILIO_PHONE_NUMBER);

    let smsResult = null;
    if (smsConfigured && emergency.phone) {
      try {
        // Import Twilio
        const twilio = require('twilio');
        const client = twilio(
          process.env.TWILIO_ACCOUNT_SID,
          process.env.TWILIO_AUTH_TOKEN
        );

        // Format phone number
        let phone = emergency.phone.replace(/\D/g, '');
        if (phone.startsWith('0')) {
          phone = '+63' + phone.substring(1);
        } else if (phone.startsWith('9') && phone.length === 10) {
          phone = '+63' + phone;
        } else if (!phone.startsWith('+')) {
          phone = '+' + phone;
        }

        // Send SMS
        const smsMessage = `Hi ${emergency.first_name}! Your emergency dental case (${emergency.emergency_type}) has been ${emergency.status}. ${message ? `Notes: ${message}` : ''} Reply STOP to unsubscribe.`;
        
        const twilioResult = await client.messages.create({
          body: smsMessage,
          from: process.env.TWILIO_PHONE_NUMBER,
          to: phone
        });

        smsResult = {
          success: true,
          messageId: twilioResult.sid,
          status: twilioResult.status
        };

        // Update notification with SMS info
        await query(`
          UPDATE notifications 
          SET sms_sent = true, sms_message_id = $1, updated_at = CURRENT_TIMESTAMP
          WHERE id = $2
        `, [twilioResult.sid, notification.id]);

        console.log(`✅ SMS sent successfully to ${phone}`);
      } catch (smsError) {
        console.error('❌ SMS sending failed:', smsError);
        smsResult = {
          success: false,
          error: smsError.message
        };
      }
    }

    console.log('✅ Emergency notification created successfully');
    res.json({
      message: 'Emergency notification sent successfully',
      notification: {
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        isRead: notification.is_read,
        createdAt: notification.created_at
      },
      sms: smsResult,
      smsConfigured: smsConfigured
    });

  } catch (error) {
    console.error('❌ Error sending emergency notification:', error);
    res.status(500).json({
      error: 'Failed to send emergency notification. Please try again.',
      details: error.message
    });
  }
});

// GET /api/emergency/sms-status - Get SMS service status
router.get('/sms-status', verifyAdmin, async (req, res) => {
  try {
    const smsStatus = {
      configured: !!(process.env.TWILIO_ACCOUNT_SID && 
                    process.env.TWILIO_AUTH_TOKEN && 
                    process.env.TWILIO_PHONE_NUMBER),
      accountSid: process.env.TWILIO_ACCOUNT_SID ? 'Set' : 'Not Set',
      authToken: process.env.TWILIO_AUTH_TOKEN ? 'Set' : 'Not Set',
      phoneNumber: process.env.TWILIO_PHONE_NUMBER || 'Not Set'
    };
    
    res.json({
      smsStatus: smsStatus
    });
  } catch (error) {
    console.error('❌ Error getting SMS status:', error);
    res.status(500).json({
      error: 'Failed to get SMS status. Please try again.',
      details: error.message
    });
  }
});

module.exports = router; 