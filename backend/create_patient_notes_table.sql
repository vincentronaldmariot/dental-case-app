-- Create patient_notes table
CREATE TABLE IF NOT EXISTS patient_notes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    admin_id UUID NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
    note TEXT NOT NULL,
    note_type VARCHAR(50) DEFAULT 'general' CHECK (note_type IN ('general', 'medical', 'appointment', 'treatment', 'emergency')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_patient_notes_patient_id ON patient_notes(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_notes_created_at ON patient_notes(created_at);

-- Add trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_patient_notes_updated_at 
    BEFORE UPDATE ON patient_notes 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert some sample notes for testing (optional)
-- INSERT INTO patient_notes (patient_id, admin_id, note, note_type) 
-- SELECT 
--     p.id, 
--     a.id, 
--     'Initial patient consultation completed. Patient shows good oral hygiene habits.',
--     'general'
-- FROM patients p, admins a 
-- WHERE a.username = 'admin' 
-- LIMIT 5; 