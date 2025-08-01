-- Add SMS tracking columns to notifications table
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS sms_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS sms_message_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_notifications_patient_id ON notifications(patient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read); 