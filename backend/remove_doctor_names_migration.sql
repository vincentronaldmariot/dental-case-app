-- Migration to remove doctor_name columns
-- This migration removes doctor name references from the database

-- Remove doctor_name column from appointments table
ALTER TABLE appointments DROP COLUMN IF EXISTS doctor_name;

-- Remove doctor_name column from treatment_records table  
ALTER TABLE treatment_records DROP COLUMN IF EXISTS doctor_name;

-- Verify the changes
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('appointments', 'treatment_records')
ORDER BY table_name, ordinal_position; 