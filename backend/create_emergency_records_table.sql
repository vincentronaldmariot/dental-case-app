-- Create emergency_records table
CREATE TABLE IF NOT EXISTS emergency_records (
    id SERIAL PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    reported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    emergency_type VARCHAR(50) NOT NULL,
    priority VARCHAR(20) NOT NULL CHECK (priority IN ('immediate', 'urgent', 'standard')),
    status VARCHAR(20) DEFAULT 'reported' CHECK (status IN ('reported', 'triaged', 'in_progress', 'resolved', 'referred')),
    description TEXT NOT NULL,
    pain_level INTEGER CHECK (pain_level >= 0 AND pain_level <= 10),
    symptoms TEXT[],
    location VARCHAR(100),
    duty_related BOOLEAN DEFAULT FALSE,
    unit_command VARCHAR(100),
    handled_by VARCHAR(100),
    first_aid_provided TEXT,
    resolved_at TIMESTAMP,
    resolution TEXT,
    follow_up_required TEXT,
    emergency_contact VARCHAR(20),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_emergency_records_patient_id ON emergency_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_emergency_records_status ON emergency_records(status);
CREATE INDEX IF NOT EXISTS idx_emergency_records_priority ON emergency_records(priority);
CREATE INDEX IF NOT EXISTS idx_emergency_records_reported_at ON emergency_records(reported_at);

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_emergency_records_updated_at 
    BEFORE UPDATE ON emergency_records 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column(); 