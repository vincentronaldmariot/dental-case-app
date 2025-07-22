-- Migration to add admin_notes field to patients table
-- Run this script to add the admin_notes column to existing patients table

-- Add admin_notes column to patients table
ALTER TABLE patients ADD COLUMN IF NOT EXISTS admin_notes TEXT;

-- Add updated_at column if it doesn't exist
ALTER TABLE patients ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW();

-- Create a trigger to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for patients table
DROP TRIGGER IF EXISTS update_patients_updated_at ON patients;
CREATE TRIGGER update_patients_updated_at
    BEFORE UPDATE ON patients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create notifications table if it doesn't exist
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    patient_id UUID REFERENCES patients(id) ON DELETE CASCADE,
    type VARCHAR(50) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Create trigger for notifications table
DROP TRIGGER IF EXISTS update_notifications_updated_at ON notifications;
CREATE TRIGGER update_notifications_updated_at
    BEFORE UPDATE ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_patients_admin_notes ON patients(admin_notes);
CREATE INDEX IF NOT EXISTS idx_notifications_patient_id ON notifications(patient_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- Grant permissions to dental_user
GRANT ALL PRIVILEGES ON TABLE notifications TO dental_user;
GRANT USAGE, SELECT ON SEQUENCE notifications_id_seq TO dental_user; 