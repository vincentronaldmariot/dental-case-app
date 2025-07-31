-- Run this in DBeaver to verify the emergency_records schema

-- 1. Check if all required columns exist
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'emergency_records' 
ORDER BY ordinal_position;

-- 2. Test the exact query that's failing in the backend
SELECT 
    er.id, er.patient_id, er.emergency_date, er.emergency_type, 
    er.description, er.severity, er.resolved, 
    COALESCE(er.status, 'reported') as status,
    COALESCE(er.priority, 'standard') as priority,
    er.handled_by, er.resolution, er.follow_up_required, er.resolved_at,
    er.emergency_contact, er.notes, er.created_at,
    p.first_name, p.last_name, p.email, p.phone
FROM emergency_records er
LEFT JOIN patients p ON er.patient_id = p.id
ORDER BY er.emergency_date DESC
LIMIT 5;

-- 3. Check if there are any records
SELECT COUNT(*) as total_records FROM emergency_records;

-- 4. Check if the indexes were created
SELECT 
    indexname, 
    indexdef 
FROM pg_indexes 
WHERE tablename = 'emergency_records'; 