
-- Add missing columns to emergency_records table
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'reported';
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS priority VARCHAR(50) DEFAULT 'standard';
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS handled_by VARCHAR(100);
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS resolution TEXT;
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS follow_up_required TEXT;
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS resolved_at TIMESTAMP;
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS emergency_contact VARCHAR(100);
ALTER TABLE emergency_records ADD COLUMN IF NOT EXISTS notes TEXT;

-- Update existing records with default values
UPDATE emergency_records SET status = 'reported' WHERE status IS NULL;
UPDATE emergency_records SET priority = 'standard' WHERE priority IS NULL;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_emergency_records_status ON emergency_records(status);
CREATE INDEX IF NOT EXISTS idx_emergency_records_priority ON emergency_records(priority);
CREATE INDEX IF NOT EXISTS idx_emergency_records_patient_id ON emergency_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_emergency_records_emergency_date ON emergency_records(emergency_date);
