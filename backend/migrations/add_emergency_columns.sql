-- Migration: Add missing columns to emergency_records table
-- This fixes the admin emergencies tab by adding the required columns

-- Add status column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'reported';

-- Add priority column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS priority VARCHAR(50) DEFAULT 'standard';

-- Add handled_by column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS handled_by VARCHAR(100);

-- Add resolution column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS resolution TEXT;

-- Add follow_up_required column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS follow_up_required TEXT;

-- Add resolved_at column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP;

-- Add emergency_contact column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS emergency_contact VARCHAR(100);

-- Add notes column
ALTER TABLE emergency_records 
ADD COLUMN IF NOT EXISTS notes TEXT;

-- Update existing records to have proper default values
UPDATE emergency_records 
SET status = 'reported' 
WHERE status IS NULL;

UPDATE emergency_records 
SET priority = 'standard' 
WHERE priority IS NULL;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_emergency_records_status ON emergency_records(status);
CREATE INDEX IF NOT EXISTS idx_emergency_records_priority ON emergency_records(priority);
CREATE INDEX IF NOT EXISTS idx_emergency_records_patient_id ON emergency_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_emergency_records_emergency_date ON emergency_records(emergency_date);

-- Verify the migration
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'emergency_records' 
ORDER BY ordinal_position; 