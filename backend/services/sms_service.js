const twilio = require('twilio');

class SMSService {
  constructor() {
    // Initialize Twilio client with environment variables
    this.client = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );
    this.fromNumber = process.env.TWILIO_PHONE_NUMBER;
  }

  /**
   * Send SMS message to a patient
   * @param {string} toPhone - Patient's phone number
   * @param {string} message - Message content
   * @returns {Promise<Object>} - Twilio message object
   */
  async sendSMS(toPhone, message) {
    try {
      console.log(`📱 Sending SMS to ${toPhone}: ${message}`);
      
      // Format phone number (ensure it starts with +)
      const formattedPhone = this.formatPhoneNumber(toPhone);
      
      const result = await this.client.messages.create({
        body: message,
        from: this.fromNumber,
        to: formattedPhone
      });

      console.log(`✅ SMS sent successfully. SID: ${result.sid}`);
      return {
        success: true,
        messageId: result.sid,
        status: result.status
      };
    } catch (error) {
      console.error('❌ SMS sending failed:', error);
      return {
        success: false,
        error: error.message,
        code: error.code
      };
    }
  }

  /**
   * Send appointment reminder SMS
   * @param {Object} patient - Patient object with phone and name
   * @param {Object} appointment - Appointment object
   * @returns {Promise<Object>} - SMS result
   */
  async sendAppointmentReminder(patient, appointment) {
    const message = `Hi ${patient.firstName}! Your dental appointment is scheduled for ${appointment.date} at ${appointment.timeSlot}. Please arrive 10 minutes early. Reply STOP to unsubscribe.`;
    
    return this.sendSMS(patient.phone, message);
  }

  /**
   * Send appointment confirmation SMS
   * @param {Object} patient - Patient object with phone and name
   * @param {Object} appointment - Appointment object
   * @returns {Promise<Object>} - SMS result
   */
  async sendAppointmentConfirmation(patient, appointment) {
    const message = `Hi ${patient.firstName}! Your dental appointment has been confirmed for ${appointment.date} at ${appointment.timeSlot}. We'll see you soon! Reply STOP to unsubscribe.`;
    
    return this.sendSMS(patient.phone, message);
  }

  /**
   * Send appointment cancellation SMS
   * @param {Object} patient - Patient object with phone and name
   * @param {Object} appointment - Appointment object
   * @returns {Promise<Object>} - SMS result
   */
  async sendAppointmentCancellation(patient, appointment) {
    const message = `Hi ${patient.firstName}! Your dental appointment for ${appointment.date} at ${appointment.timeSlot} has been cancelled. Please contact us to reschedule. Reply STOP to unsubscribe.`;
    
    return this.sendSMS(patient.phone, message);
  }

  /**
   * Send emergency notification SMS
   * @param {Object} patient - Patient object with phone and name
   * @param {Object} emergency - Emergency record object
   * @returns {Promise<Object>} - SMS result
   */
  async sendEmergencyNotification(patient, emergency) {
    const message = `Hi ${patient.firstName}! Your emergency dental case (${emergency.emergencyTypeDisplay}) has been ${emergency.statusDisplay}. ${emergency.notes ? `Notes: ${emergency.notes}` : ''} Reply STOP to unsubscribe.`;
    
    return this.sendSMS(patient.phone, message);
  }

  /**
   * Send treatment update SMS
   * @param {Object} patient - Patient object with phone and name
   * @param {string} treatmentUpdate - Treatment update message
   * @returns {Promise<Object>} - SMS result
   */
  async sendTreatmentUpdate(patient, treatmentUpdate) {
    const message = `Hi ${patient.firstName}! ${treatmentUpdate} Reply STOP to unsubscribe.`;
    
    return this.sendSMS(patient.phone, message);
  }

  /**
   * Send health tip SMS
   * @param {Object} patient - Patient object with phone and name
   * @param {string} healthTip - Health tip message
   * @returns {Promise<Object>} - SMS result
   */
  async sendHealthTip(patient, healthTip) {
    const message = `Hi ${patient.firstName}! Dental Health Tip: ${healthTip} Reply STOP to unsubscribe.`;
    
    return this.sendSMS(patient.phone, message);
  }

  /**
   * Format phone number for international SMS
   * @param {string} phone - Phone number
   * @returns {string} - Formatted phone number
   */
  formatPhoneNumber(phone) {
    // Remove all non-digit characters
    let cleaned = phone.replace(/\D/g, '');
    
    // If it starts with 0, replace with +63 (Philippines)
    if (cleaned.startsWith('0')) {
      cleaned = '+63' + cleaned.substring(1);
    }
    // If it starts with 9, add +63 (Philippines)
    else if (cleaned.startsWith('9') && cleaned.length === 10) {
      cleaned = '+63' + cleaned;
    }
    // If it doesn't start with +, add it
    else if (!cleaned.startsWith('+')) {
      cleaned = '+' + cleaned;
    }
    
    return cleaned;
  }

  /**
   * Validate if SMS service is properly configured
   * @returns {boolean} - True if configured
   */
  isConfigured() {
    return !!(process.env.TWILIO_ACCOUNT_SID && 
              process.env.TWILIO_AUTH_TOKEN && 
              process.env.TWILIO_PHONE_NUMBER);
  }

  /**
   * Get SMS service status
   * @returns {Object} - Service status
   */
  getStatus() {
    return {
      configured: this.isConfigured(),
      accountSid: process.env.TWILIO_ACCOUNT_SID ? 'Set' : 'Not Set',
      authToken: process.env.TWILIO_AUTH_TOKEN ? 'Set' : 'Not Set',
      phoneNumber: process.env.TWILIO_PHONE_NUMBER || 'Not Set'
    };
  }
}

module.exports = new SMSService(); 