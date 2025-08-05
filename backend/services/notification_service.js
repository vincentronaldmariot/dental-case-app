const { query } = require('../config/database');
const smsService = require('./sms_service');
const emailService = require('./email_service');

class NotificationService {
  /**
   * Create a notification and optionally send SMS and Email
   * @param {Object} options - Notification options
   * @returns {Promise<Object>} - Created notification
   */
  async createNotification(options) {
    const {
      patientId,
      title,
      message,
      type = 'general',
      sendSMS = false,
      smsMessage = null,
      sendEmail = false,
      emailSubject = null,
      emailHTML = null,
      emailText = null
    } = options;

    try {
      console.log(`📋 Creating notification for patient ${patientId}: ${title}`);

      // Create notification in database
      const result = await query(`
        INSERT INTO notifications (patient_id, title, message, type, created_at)
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
        RETURNING id, title, message, type, is_read, created_at
      `, [patientId, title, message, type]);

      const notification = result.rows[0];

      // Get patient information for notifications
      const patientResult = await query(`
        SELECT first_name, last_name, phone, email
        FROM patients
        WHERE id = $1
      `, [patientId]);

      if (patientResult.rows.length > 0) {
        const patient = patientResult.rows[0];

        // Send SMS if requested and SMS service is configured
        if (sendSMS && smsService.isConfigured()) {
          try {
            const smsText = smsMessage || message;
            
            const smsResult = await smsService.sendSMS(patient.phone, smsText);
            
            if (smsResult.success) {
              console.log(`✅ SMS sent successfully for notification ${notification.id}`);
              
              // Update notification with SMS info
              await query(`
                UPDATE notifications 
                SET sms_sent = true, sms_message_id = $1, updated_at = CURRENT_TIMESTAMP
                WHERE id = $2
              `, [smsResult.messageId, notification.id]);
            } else {
              console.log(`⚠️ SMS failed for notification ${notification.id}: ${smsResult.error}`);
            }
          } catch (smsError) {
            console.error('❌ SMS sending error:', smsError);
            // Don't fail the notification creation if SMS fails
          }
        }

        // Send Email if requested and Email service is configured
        if (sendEmail && emailService.isConfigured && patient.email) {
          try {
            const emailResult = await emailService.sendEmail({
              to: patient.email,
              subject: emailSubject || title,
              html: emailHTML,
              text: emailText || message
            });
            
            if (emailResult.success) {
              console.log(`✅ Email sent successfully for notification ${notification.id}`);
              
              // Update notification with Email info
              await query(`
                UPDATE notifications 
                SET email_sent = true, email_message_id = $1, updated_at = CURRENT_TIMESTAMP
                WHERE id = $2
              `, [emailResult.messageId, notification.id]);
            } else {
              console.log(`⚠️ Email failed for notification ${notification.id}: ${emailResult.error}`);
            }
          } catch (emailError) {
            console.error('❌ Email sending error:', emailError);
            // Don't fail the notification creation if Email fails
          }
        }
      }

      return {
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        isRead: notification.is_read,
        createdAt: notification.created_at
      };

    } catch (error) {
      console.error('❌ Error creating notification:', error);
      throw error;
    }
  }

  /**
   * Send appointment reminder notification with SMS and Email
   * @param {Object} appointment - Appointment object
   * @returns {Promise<Object>} - Created notification
   */
  async sendAppointmentReminder(appointment) {
    const title = 'Appointment Reminder';
    const message = `Your dental appointment is scheduled for ${appointment.date} at ${appointment.timeSlot}. Please arrive 10 minutes early.`;
    
    // Get patient info for email
    const patientResult = await query(`
      SELECT first_name, last_name, email
      FROM patients
      WHERE id = $1
    `, [appointment.patientId]);
    
    let emailHTML = null;
    let emailText = null;
    
    if (patientResult.rows.length > 0) {
      const patient = patientResult.rows[0];
      emailHTML = emailService.generateAppointmentReminderHTML(appointment, patient);
      emailText = emailService.generateAppointmentReminderText(appointment, patient);
    }
    
    return this.createNotification({
      patientId: appointment.patientId,
      title,
      message,
      type: 'appointment',
      sendSMS: true,
      smsMessage: `Hi! Your dental appointment is scheduled for ${appointment.date} at ${appointment.timeSlot}. Please arrive 10 minutes early. Reply STOP to unsubscribe.`,
      sendEmail: true,
      emailSubject: '🦷 Dental Appointment Reminder',
      emailHTML: emailHTML,
      emailText: emailText
    });
  }

  /**
   * Send appointment confirmation notification with SMS and Email
   * @param {Object} appointment - Appointment object
   * @returns {Promise<Object>} - Created notification
   */
  async sendAppointmentConfirmation(appointment) {
    const title = 'Appointment Confirmed';
    const message = `Your dental appointment has been confirmed for ${appointment.date} at ${appointment.timeSlot}. We'll see you soon!`;
    
    // Get patient info for email
    const patientResult = await query(`
      SELECT first_name, last_name, email
      FROM patients
      WHERE id = $1
    `, [appointment.patientId]);
    
    let emailHTML = null;
    let emailText = null;
    
    if (patientResult.rows.length > 0) {
      const patient = patientResult.rows[0];
      emailHTML = emailService.generateAppointmentConfirmationHTML(appointment, patient);
      emailText = emailService.generateAppointmentConfirmationText(appointment, patient);
    }
    
    return this.createNotification({
      patientId: appointment.patientId,
      title,
      message,
      type: 'appointment',
      sendSMS: true,
      smsMessage: `Hi! Your dental appointment has been confirmed for ${appointment.date} at ${appointment.timeSlot}. We'll see you soon! Reply STOP to unsubscribe.`,
      sendEmail: true,
      emailSubject: '✅ Dental Appointment Confirmed',
      emailHTML: emailHTML,
      emailText: emailText
    });
  }

  /**
   * Send appointment cancellation notification with SMS and Email
   * @param {Object} appointment - Appointment object
   * @returns {Promise<Object>} - Created notification
   */
  async sendAppointmentCancellation(appointment) {
    const title = 'Appointment Cancelled';
    const message = `Your dental appointment for ${appointment.date} at ${appointment.timeSlot} has been cancelled. Please contact us to reschedule.`;
    
    // Get patient info for email
    const patientResult = await query(`
      SELECT first_name, last_name, email
      FROM patients
      WHERE id = $1
    `, [appointment.patientId]);
    
    let emailHTML = null;
    let emailText = null;
    
    if (patientResult.rows.length > 0) {
      const patient = patientResult.rows[0];
      emailHTML = emailService.generateAppointmentCancellationHTML(appointment, patient);
      emailText = emailService.generateAppointmentCancellationText(appointment, patient);
    }
    
    return this.createNotification({
      patientId: appointment.patientId,
      title,
      message,
      type: 'appointment',
      sendSMS: true,
      smsMessage: `Hi! Your dental appointment for ${appointment.date} at ${appointment.timeSlot} has been cancelled. Please contact us to reschedule. Reply STOP to unsubscribe.`,
      sendEmail: true,
      emailSubject: '❌ Dental Appointment Cancelled',
      emailHTML: emailHTML,
      emailText: emailText
    });
  }

  /**
   * Send emergency notification with SMS and Email
   * @param {Object} emergency - Emergency record object
   * @returns {Promise<Object>} - Created notification
   */
  async sendEmergencyNotification(emergency) {
    const title = 'Emergency Case Update';
    const message = `Your emergency dental case (${emergency.emergencyTypeDisplay}) has been ${emergency.statusDisplay}. ${emergency.notes ? `Notes: ${emergency.notes}` : ''}`;
    
    // Get patient info for email
    const patientResult = await query(`
      SELECT first_name, last_name, email
      FROM patients
      WHERE id = $1
    `, [emergency.patientId]);
    
    let emailHTML = null;
    let emailText = null;
    
    if (patientResult.rows.length > 0) {
      const patient = patientResult.rows[0];
      emailHTML = emailService.generateEmergencyNotificationHTML(emergency, patient);
      emailText = emailService.generateEmergencyNotificationText(emergency, patient);
    }
    
    return this.createNotification({
      patientId: emergency.patientId,
      title,
      message,
      type: 'emergency',
      sendSMS: true,
      smsMessage: `Hi! Your emergency dental case (${emergency.emergencyTypeDisplay}) has been ${emergency.statusDisplay}. ${emergency.notes ? `Notes: ${emergency.notes}` : ''} Reply STOP to unsubscribe.`,
      sendEmail: true,
      emailSubject: '🚨 Emergency Dental Case Update',
      emailHTML: emailHTML,
      emailText: emailText
    });
  }

  /**
   * Send treatment update notification with SMS and Email
   * @param {string} patientId - Patient ID
   * @param {string} treatmentUpdate - Treatment update message
   * @returns {Promise<Object>} - Created notification
   */
  async sendTreatmentUpdate(patientId, treatmentUpdate) {
    const title = 'Treatment Update';
    const message = treatmentUpdate;
    
    // Get patient info for email
    const patientResult = await query(`
      SELECT first_name, last_name, email
      FROM patients
      WHERE id = $1
    `, [patientId]);
    
    let emailHTML = null;
    let emailText = null;
    
    if (patientResult.rows.length > 0) {
      const patient = patientResult.rows[0];
      emailHTML = emailService.generateTreatmentUpdateHTML(patient, treatmentUpdate);
      emailText = emailService.generateTreatmentUpdateText(patient, treatmentUpdate);
    }
    
    return this.createNotification({
      patientId,
      title,
      message,
      type: 'treatment',
      sendSMS: true,
      smsMessage: `Hi! ${treatmentUpdate} Reply STOP to unsubscribe.`,
      sendEmail: true,
      emailSubject: '📋 Dental Treatment Update',
      emailHTML: emailHTML,
      emailText: emailText
    });
  }

  /**
   * Send health tip notification with SMS and Email
   * @param {string} patientId - Patient ID
   * @param {string} healthTip - Health tip message
   * @returns {Promise<Object>} - Created notification
   */
  async sendHealthTip(patientId, healthTip) {
    const title = 'Dental Health Tip';
    const message = healthTip;
    
    // Get patient info for email
    const patientResult = await query(`
      SELECT first_name, last_name, email
      FROM patients
      WHERE id = $1
    `, [patientId]);
    
    let emailHTML = null;
    let emailText = null;
    
    if (patientResult.rows.length > 0) {
      const patient = patientResult.rows[0];
      emailHTML = emailService.generateHealthTipHTML(patient, healthTip);
      emailText = emailService.generateHealthTipText(patient, healthTip);
    }
    
    return this.createNotification({
      patientId,
      title,
      message,
      type: 'health_tip',
      sendSMS: true,
      smsMessage: `Hi! Dental Health Tip: ${healthTip} Reply STOP to unsubscribe.`,
      sendEmail: true,
      emailSubject: '💡 Dental Health Tip',
      emailHTML: emailHTML,
      emailText: emailText
    });
  }

  /**
   * Get notifications for a patient
   * @param {string} patientId - Patient ID
   * @returns {Promise<Array>} - Array of notifications
   */
  async getNotifications(patientId) {
    try {
      const result = await query(`
        SELECT id, title, message, type, is_read, created_at, sms_sent, sms_message_id, email_sent, email_message_id
        FROM notifications 
        WHERE patient_id = $1
        ORDER BY created_at DESC
        LIMIT 50
      `, [patientId]);

      return result.rows.map(notification => ({
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        isRead: notification.is_read,
        createdAt: notification.created_at,
        smsSent: notification.sms_sent || false,
        smsMessageId: notification.sms_message_id,
        emailSent: notification.email_sent || false,
        emailMessageId: notification.email_message_id
      }));
    } catch (error) {
      console.error('❌ Error getting notifications:', error);
      throw error;
    }
  }

  /**
   * Mark notification as read
   * @param {string} notificationId - Notification ID
   * @param {string} patientId - Patient ID
   * @returns {Promise<Object>} - Updated notification
   */
  async markAsRead(notificationId, patientId) {
    try {
      const result = await query(`
        UPDATE notifications 
        SET is_read = true, updated_at = CURRENT_TIMESTAMP
        WHERE id = $1 AND patient_id = $2
        RETURNING id, is_read
      `, [notificationId, patientId]);

      if (result.rows.length === 0) {
        throw new Error('Notification not found');
      }

      return {
        id: result.rows[0].id,
        isRead: result.rows[0].is_read
      };
    } catch (error) {
      console.error('❌ Error marking notification as read:', error);
      throw error;
    }
  }

  /**
   * Get unread notifications count
   * @param {string} patientId - Patient ID
   * @returns {Promise<number>} - Unread count
   */
  async getUnreadCount(patientId) {
    try {
      const result = await query(`
        SELECT COUNT(*) as count
        FROM notifications 
        WHERE patient_id = $1 AND is_read = false
      `, [patientId]);

      return parseInt(result.rows[0].count);
    } catch (error) {
      console.error('❌ Error getting unread count:', error);
      throw error;
    }
  }

  /**
   * Get SMS service status
   * @returns {Object} - SMS service status
   */
  getSMSStatus() {
    return smsService.getStatus();
  }

  /**
   * Get Email service status
   * @returns {Object} - Email service status
   */
  getEmailStatus() {
    return emailService.getStatus();
  }

  /**
   * Get combined notification service status
   * @returns {Object} - Combined service status
   */
  getNotificationStatus() {
    return {
      sms: this.getSMSStatus(),
      email: this.getEmailStatus()
    };
  }
}

module.exports = new NotificationService(); 