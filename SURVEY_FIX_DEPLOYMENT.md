# Survey Submission Fix - Deployment Guide

## Issue Summary
The survey submission is failing with error: "Cannot read properties of undefined (reading 'id')" because:
1. The Railway database doesn't have the kiosk patient record
2. The dental_surveys table has a foreign key constraint that requires patient_id to exist in patients table

## Fix Steps

### 1. Database Fix (Run on Railway Database)

Connect to the Railway PostgreSQL database and run these SQL commands:

```sql
-- Create kiosk patient if it doesn't exist
INSERT INTO patients (
  id, first_name, last_name, email, phone, password_hash, 
  date_of_birth, address, emergency_contact, emergency_phone,
  created_at, updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  'Kiosk',
  'User',
  'kiosk@dental.app',
  '00000000000',
  'kiosk_hash',
  '2000-01-01',
  'Kiosk Location',
  'Kiosk Emergency',
  '00000000000',
  CURRENT_TIMESTAMP,
  CURRENT_TIMESTAMP
) ON CONFLICT (id) DO NOTHING;

-- Ensure dental_surveys table exists with proper structure
CREATE TABLE IF NOT EXISTS dental_surveys (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id UUID NOT NULL UNIQUE,
  survey_data JSONB NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_dental_surveys_patient_id 
ON dental_surveys(patient_id);

-- Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_dental_surveys_updated_at ON dental_surveys;
CREATE TRIGGER update_dental_surveys_updated_at 
BEFORE UPDATE ON dental_surveys 
FOR EACH ROW 
EXECUTE FUNCTION update_updated_at_column();
```

### 2. Backend Code Update

The backend code has been updated with:
- Better error handling
- UPSERT logic for survey submission
- Automatic table creation
- Comprehensive logging

### 3. Test the Fix

After applying the database fix, test the survey submission:

```bash
# Test with curl
curl -X POST "https://afp-dental-app-production.up.railway.app/api/surveys" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer kiosk_token" \
  -d '{
    "surveyData": {
      "patient_info": {
        "name": "Test Patient",
        "email": "test@example.com"
      },
      "submitted_at": "2025-07-29T23:20:11.142Z",
      "submitted_via": "kiosk"
    }
  }'
```

Expected response:
```json
{
  "message": "Survey submitted successfully",
  "survey": {
    "id": "uuid-here",
    "patientId": "00000000-0000-0000-0000-000000000000",
    "completedAt": "2025-07-29T23:20:11.142Z",
    "updatedAt": "2025-07-29T23:20:11.142Z"
  }
}
```

### 4. App Configuration

The Flutter app is configured to use the online server:
- `isOnlineMode = true` in `lib/config/app_config.dart`
- API base URL: `https://afp-dental-app-production.up.railway.app/api`

## Verification

1. ✅ Local server survey submission works
2. ✅ Database schema is correct
3. ✅ Kiosk patient exists
4. ⏳ Railway database needs manual fix
5. ⏳ Railway backend code needs deployment

## Next Steps

1. Access Railway database and run the SQL fix
2. Deploy the updated backend code to Railway
3. Test survey submission on Railway
4. Verify the Flutter app can submit surveys successfully 