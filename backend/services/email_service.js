const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    this.transporter = null;
    this.isConfigured = false;
    this.config = {
      host: process.env.EMAIL_HOST || 'smtp.gmail.com',
      port: process.env.EMAIL_PORT || 587,
      secure: process.env.EMAIL_SECURE === 'true',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    };
    this.fromEmail = process.env.EMAIL_FROM || process.env.EMAIL_USER;
    this.fromName = process.env.EMAIL_FROM_NAME || 'Dental Case App';
    
    this.initialize();
  }

  /**
   * Initialize email service
   */
  initialize() {
    try {
      if (this.config.auth.user && this.config.auth.pass) {
        this.transporter = nodemailer.createTransporter(this.config);
        this.isConfigured = true;
        console.log('✅ Email service initialized successfully');
      } else {
        console.log('⚠️ Email service not configured - missing credentials');
        this.isConfigured = false;
      }
    } catch (error) {
      console.error('❌ Error initializing email service:', error);
      this.isConfigured = false;
    }
  }

  /**
   * Send email
   * @param {Object} options - Email options
   * @returns {Promise<Object>} - Email result
   */
  async sendEmail(options) {
    const {
      to,
      subject,
      html,
      text,
      attachments = []
    } = options;

    if (!this.isConfigured) {
      return {
        success: false,
        error: 'Email service not configured'
      };
    }

    try {
      const mailOptions = {
        from: `"${this.fromName}" <${this.fromEmail}>`,
        to: to,
        subject: subject,
        html: html,
        text: text,
        attachments: attachments
      };

      const result = await this.transporter.sendMail(mailOptions);
      
      console.log(`✅ Email sent successfully to ${to}: ${result.messageId}`);
      
      return {
        success: true,
        messageId: result.messageId,
        response: result.response
      };
    } catch (error) {
      console.error('❌ Error sending email:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Send appointment reminder email
   * @param {Object} appointment - Appointment object
   * @param {Object} patient - Patient object
   * @returns {Promise<Object>} - Email result
   */
  async sendAppointmentReminder(appointment, patient) {
    const subject = '🦷 Dental Appointment Reminder';
    const html = this.generateAppointmentReminderHTML(appointment, patient);
    const text = this.generateAppointmentReminderText(appointment, patient);

    return this.sendEmail({
      to: patient.email,
      subject: subject,
      html: html,
      text: text
    });
  }

  /**
   * Send appointment confirmation email
   * @param {Object} appointment - Appointment object
   * @param {Object} patient - Patient object
   * @returns {Promise<Object>} - Email result
   */
  async sendAppointmentConfirmation(appointment, patient) {
    const subject = '✅ Dental Appointment Confirmed';
    const html = this.generateAppointmentConfirmationHTML(appointment, patient);
    const text = this.generateAppointmentConfirmationText(appointment, patient);

    return this.sendEmail({
      to: patient.email,
      subject: subject,
      html: html,
      text: text
    });
  }

  /**
   * Send appointment cancellation email
   * @param {Object} appointment - Appointment object
   * @param {Object} patient - Patient object
   * @returns {Promise<Object>} - Email result
   */
  async sendAppointmentCancellation(appointment, patient) {
    const subject = '❌ Dental Appointment Cancelled';
    const html = this.generateAppointmentCancellationHTML(appointment, patient);
    const text = this.generateAppointmentCancellationText(appointment, patient);

    return this.sendEmail({
      to: patient.email,
      subject: subject,
      html: html,
      text: text
    });
  }

  /**
   * Send emergency notification email
   * @param {Object} emergency - Emergency record object
   * @param {Object} patient - Patient object
   * @returns {Promise<Object>} - Email result
   */
  async sendEmergencyNotification(emergency, patient) {
    const subject = '🚨 Emergency Dental Case Update';
    const html = this.generateEmergencyNotificationHTML(emergency, patient);
    const text = this.generateEmergencyNotificationText(emergency, patient);

    return this.sendEmail({
      to: patient.email,
      subject: subject,
      html: html,
      text: text
    });
  }

  /**
   * Send treatment update email
   * @param {Object} patient - Patient object
   * @param {string} treatmentUpdate - Treatment update message
   * @returns {Promise<Object>} - Email result
   */
  async sendTreatmentUpdate(patient, treatmentUpdate) {
    const subject = '📋 Dental Treatment Update';
    const html = this.generateTreatmentUpdateHTML(patient, treatmentUpdate);
    const text = this.generateTreatmentUpdateText(patient, treatmentUpdate);

    return this.sendEmail({
      to: patient.email,
      subject: subject,
      html: html,
      text: text
    });
  }

  /**
   * Send health tip email
   * @param {Object} patient - Patient object
   * @param {string} healthTip - Health tip message
   * @returns {Promise<Object>} - Email result
   */
  async sendHealthTip(patient, healthTip) {
    const subject = '💡 Dental Health Tip';
    const html = this.generateHealthTipHTML(patient, healthTip);
    const text = this.generateHealthTipText(patient, healthTip);

    return this.sendEmail({
      to: patient.email,
      subject: subject,
      html: html,
      text: text
    });
  }

  /**
   * Generate appointment reminder HTML
   */
  generateAppointmentReminderHTML(appointment, patient) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Appointment Reminder</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .appointment-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #667eea; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
          .btn { display: inline-block; background: #667eea; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🦷 Dental Appointment Reminder</h1>
            <p>Hello ${patient.firstName} ${patient.lastName}</p>
          </div>
          <div class="content">
            <p>This is a friendly reminder about your upcoming dental appointment.</p>
            
            <div class="appointment-details">
              <h3>Appointment Details:</h3>
              <p><strong>Date:</strong> ${appointment.date}</p>
              <p><strong>Time:</strong> ${appointment.timeSlot}</p>
              <p><strong>Service:</strong> ${appointment.service}</p>
            </div>
            
            <p><strong>Important:</strong> Please arrive 10 minutes before your scheduled time.</p>
            
            <p>If you need to reschedule or cancel your appointment, please contact us as soon as possible.</p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="#" class="btn">Contact Us</a>
            </div>
          </div>
          <div class="footer">
            <p>This is an automated reminder from the Dental Case App.</p>
            <p>If you have any questions, please contact our office.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  /**
   * Generate appointment reminder text
   */
  generateAppointmentReminderText(appointment, patient) {
    return `
Dental Appointment Reminder

Hello ${patient.firstName} ${patient.lastName},

This is a friendly reminder about your upcoming dental appointment.

Appointment Details:
- Date: ${appointment.date}
- Time: ${appointment.timeSlot}
- Service: ${appointment.service}

Important: Please arrive 10 minutes before your scheduled time.

If you need to reschedule or cancel your appointment, please contact us as soon as possible.

This is an automated reminder from the Dental Case App.
    `;
  }

  /**
   * Generate appointment confirmation HTML
   */
  generateAppointmentConfirmationHTML(appointment, patient) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Appointment Confirmed</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .appointment-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #4CAF50; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
          .btn { display: inline-block; background: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>✅ Dental Appointment Confirmed</h1>
            <p>Hello ${patient.firstName} ${patient.lastName}</p>
          </div>
          <div class="content">
            <p>Great news! Your dental appointment has been confirmed.</p>
            
            <div class="appointment-details">
              <h3>Confirmed Appointment:</h3>
              <p><strong>Date:</strong> ${appointment.date}</p>
              <p><strong>Time:</strong> ${appointment.timeSlot}</p>
              <p><strong>Service:</strong> ${appointment.service}</p>
            </div>
            
            <p><strong>What to expect:</strong></p>
            <ul>
              <li>Please arrive 10 minutes before your scheduled time</li>
              <li>Bring your ID and any relevant medical information</li>
              <li>If you need to cancel, please give us 24 hours notice</li>
            </ul>
            
            <p>We look forward to seeing you!</p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="#" class="btn">View Appointment</a>
            </div>
          </div>
          <div class="footer">
            <p>This is an automated confirmation from the Dental Case App.</p>
            <p>If you have any questions, please contact our office.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  /**
   * Generate appointment confirmation text
   */
  generateAppointmentConfirmationText(appointment, patient) {
    return `
Dental Appointment Confirmed

Hello ${patient.firstName} ${patient.lastName},

Great news! Your dental appointment has been confirmed.

Confirmed Appointment:
- Date: ${appointment.date}
- Time: ${appointment.timeSlot}
- Service: ${appointment.service}

What to expect:
- Please arrive 10 minutes before your scheduled time
- Bring your ID and any relevant medical information
- If you need to cancel, please give us 24 hours notice

We look forward to seeing you!

This is an automated confirmation from the Dental Case App.
    `;
  }

  /**
   * Generate appointment cancellation HTML
   */
  generateAppointmentCancellationHTML(appointment, patient) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Appointment Cancelled</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #f44336 0%, #d32f2f 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .appointment-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f44336; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
          .btn { display: inline-block; background: #f44336; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>❌ Dental Appointment Cancelled</h1>
            <p>Hello ${patient.firstName} ${patient.lastName}</p>
          </div>
          <div class="content">
            <p>Your dental appointment has been cancelled.</p>
            
            <div class="appointment-details">
              <h3>Cancelled Appointment:</h3>
              <p><strong>Date:</strong> ${appointment.date}</p>
              <p><strong>Time:</strong> ${appointment.timeSlot}</p>
              <p><strong>Service:</strong> ${appointment.service}</p>
            </div>
            
            <p>Please contact us to reschedule your appointment at your convenience.</p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="#" class="btn">Reschedule Appointment</a>
            </div>
          </div>
          <div class="footer">
            <p>This is an automated notification from the Dental Case App.</p>
            <p>If you have any questions, please contact our office.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  /**
   * Generate appointment cancellation text
   */
  generateAppointmentCancellationText(appointment, patient) {
    return `
Dental Appointment Cancelled

Hello ${patient.firstName} ${patient.lastName},

Your dental appointment has been cancelled.

Cancelled Appointment:
- Date: ${appointment.date}
- Time: ${appointment.timeSlot}
- Service: ${appointment.service}

Please contact us to reschedule your appointment at your convenience.

This is an automated notification from the Dental Case App.
    `;
  }

  /**
   * Generate emergency notification HTML
   */
  generateEmergencyNotificationHTML(emergency, patient) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Emergency Case Update</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #ff9800 0%, #f57c00 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .emergency-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #ff9800; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
          .btn { display: inline-block; background: #ff9800; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🚨 Emergency Case Update</h1>
            <p>Hello ${patient.firstName} ${patient.lastName}</p>
          </div>
          <div class="content">
            <p>Your emergency dental case has been updated.</p>
            
            <div class="emergency-details">
              <h3>Emergency Details:</h3>
              <p><strong>Type:</strong> ${emergency.emergencyTypeDisplay}</p>
              <p><strong>Status:</strong> ${emergency.statusDisplay}</p>
              <p><strong>Priority:</strong> ${emergency.priorityDisplay}</p>
              <p><strong>Reported:</strong> ${emergency.reportedAt}</p>
              ${emergency.notes ? `<p><strong>Notes:</strong> ${emergency.notes}</p>` : ''}
            </div>
            
            <p>If you have any questions or concerns, please contact us immediately.</p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="#" class="btn">Contact Emergency</a>
            </div>
          </div>
          <div class="footer">
            <p>This is an automated notification from the Dental Case App.</p>
            <p>For urgent matters, please call our emergency line.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  /**
   * Generate emergency notification text
   */
  generateEmergencyNotificationText(emergency, patient) {
    return `
Emergency Case Update

Hello ${patient.firstName} ${patient.lastName},

Your emergency dental case has been updated.

Emergency Details:
- Type: ${emergency.emergencyTypeDisplay}
- Status: ${emergency.statusDisplay}
- Priority: ${emergency.priorityDisplay}
- Reported: ${emergency.reportedAt}
${emergency.notes ? `- Notes: ${emergency.notes}` : ''}

If you have any questions or concerns, please contact us immediately.

This is an automated notification from the Dental Case App.
    `;
  }

  /**
   * Generate treatment update HTML
   */
  generateTreatmentUpdateHTML(patient, treatmentUpdate) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Treatment Update</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #2196F3 0%, #1976D2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .treatment-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #2196F3; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
          .btn { display: inline-block; background: #2196F3; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>📋 Treatment Update</h1>
            <p>Hello ${patient.firstName} ${patient.lastName}</p>
          </div>
          <div class="content">
            <p>You have a new treatment update from your dental care team.</p>
            
            <div class="treatment-details">
              <h3>Update:</h3>
              <p>${treatmentUpdate}</p>
            </div>
            
            <p>If you have any questions about your treatment, please don't hesitate to contact us.</p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="#" class="btn">Contact Us</a>
            </div>
          </div>
          <div class="footer">
            <p>This is an automated notification from the Dental Case App.</p>
            <p>If you have any questions, please contact our office.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  /**
   * Generate treatment update text
   */
  generateTreatmentUpdateText(patient, treatmentUpdate) {
    return `
Treatment Update

Hello ${patient.firstName} ${patient.lastName},

You have a new treatment update from your dental care team.

Update:
${treatmentUpdate}

If you have any questions about your treatment, please don't hesitate to contact us.

This is an automated notification from the Dental Case App.
    `;
  }

  /**
   * Generate health tip HTML
   */
  generateHealthTipHTML(patient, healthTip) {
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Dental Health Tip</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
          .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
          .tip-details { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #4CAF50; }
          .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
          .btn { display: inline-block; background: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; margin: 10px 5px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>💡 Dental Health Tip</h1>
            <p>Hello ${patient.firstName} ${patient.lastName}</p>
          </div>
          <div class="content">
            <p>Here's a helpful dental health tip for you!</p>
            
            <div class="tip-details">
              <h3>Today's Tip:</h3>
              <p>${healthTip}</p>
            </div>
            
            <p>Remember, good oral hygiene is essential for your overall health.</p>
            
            <div style="text-align: center; margin: 30px 0;">
              <a href="#" class="btn">Learn More</a>
            </div>
          </div>
          <div class="footer">
            <p>This is an automated notification from the Dental Case App.</p>
            <p>If you have any questions, please contact our office.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  /**
   * Generate health tip text
   */
  generateHealthTipText(patient, healthTip) {
    return `
Dental Health Tip

Hello ${patient.firstName} ${patient.lastName},

Here's a helpful dental health tip for you!

Today's Tip:
${healthTip}

Remember, good oral hygiene is essential for your overall health.

This is an automated notification from the Dental Case App.
    `;
  }

  /**
   * Get email service status
   * @returns {Object} - Email service status
   */
  getStatus() {
    return {
      configured: this.isConfigured,
      host: this.config.host,
      port: this.config.port,
      secure: this.config.secure,
      fromEmail: this.fromEmail,
      fromName: this.fromName
    };
  }
}

module.exports = new EmailService(); 