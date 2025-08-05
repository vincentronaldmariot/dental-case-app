-- Add email columns to notifications table
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS email_sent BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS email_message_id VARCHAR(255);

-- Add index for email_sent for better query performance
CREATE INDEX IF NOT EXISTS idx_notifications_email_sent ON notifications(email_sent);

-- Add index for email_message_id for tracking
CREATE INDEX IF NOT EXISTS idx_notifications_email_message_id ON notifications(email_message_id); 