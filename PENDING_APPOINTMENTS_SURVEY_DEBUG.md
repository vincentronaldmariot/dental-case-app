# Pending Appointments Survey Data Debug

## Issue
The patient self-assessment survey data is not showing in the pending appointment details.

## Root Cause Found ✅
The issue was that the database contains survey data in the old format (question1, question2, etc.), but the admin dashboard was expecting the new format with specific field names (tooth_conditions, tartar_level, etc.).

**Old Format in Database:**
```json
{
  "question1": "Yes",
  "question2": "Not specified",
  "question3": "Not specified",
  "question4": "Not specified",
  "question5": "Not specified",
  "question6": "Not specified",
  "question7": "Not specified",
  "question8": "Not specified"
}
```

**New Format Expected:**
```json
{
  "tooth_conditions": {...},
  "tartar_level": "...",
  "tooth_sensitive": true/false,
  "tooth_pain": true/false,
  "damaged_fillings": {...},
  "need_dentures": true/false,
  "has_missing_teeth": true/false,
  "missing_tooth_conditions": {...},
  "patient_info": {...}
}
```

## Current Implementation Status

### ✅ What's Working:
1. **Backend API**: The `/api/admin/pending-appointments` endpoint properly fetches survey data:
   ```sql
   SELECT 
     a.id AS appointment_id,
     a.service,
     a.appointment_date AS booking_date,
     a.time_slot,
     a.status,
     p.first_name, p.last_name, p.email,
     p.phone,
     p.classification,
     s.survey_data  -- ✅ Survey data is being fetched
   FROM appointments a
   JOIN patients p ON a.patient_id = p.id
   LEFT JOIN dental_surveys s ON s.patient_id = p.id
   WHERE a.status = 'pending'
   ```

2. **Frontend Dialog**: The `_showProceedDialog` method properly displays survey data:
   - Shows all 8 questions from the old self-assessment survey
   - Has proper fallback for when no survey data is available
   - Includes debug logging to track survey data
   - **NEW**: Added format conversion to handle both old and new survey formats

3. **Debug Logging**: Added enhanced logging to track survey data:
   ```dart
   print('🔍 Survey data for ${appointment['patient_name']}: ${appointment['survey_data']}');
   print('🔍 Has survey data: ${appointment['has_survey_data']}');
   print('📋 Converted survey: $convertedSurvey');
   ```

4. **Format Conversion**: Added `_convertOldSurveyFormat()` method to convert old survey format to new format:
   - Maps question1 → tooth_conditions
   - Maps question2 → tartar_level
   - Maps question3 → tooth_sensitive
   - Maps question4 → tooth_pain
   - Maps question5 → damaged_fillings
   - Maps question6 → need_dentures
   - Maps question7 → has_missing_teeth + missing_tooth_conditions
   - Maps question8 → patient_info.last_visit

### 🔍 Potential Issues:

1. **No Survey Data**: The patient may not have completed a survey yet
2. **Database Connection**: Survey data might not be properly linked to the patient
3. **Data Format**: Survey data might be in an unexpected format
4. **~~Format Mismatch~~**: ✅ **FIXED** - Old survey format was not being converted to new format

## Debugging Steps

### Step 1: Check Console Logs
Run the app and check the console output when viewing pending appointments. Look for:
- `🔍 Survey data for [patient_name]: [data]`
- `🔍 Has survey data: [true/false]`

### Step 2: Verify Database
Check if survey data exists in the database:
```sql
SELECT 
  p.first_name, p.last_name,
  s.survey_data,
  s.created_at
FROM patients p
LEFT JOIN dental_surveys s ON s.patient_id = p.id
WHERE p.id IN (
  SELECT patient_id FROM appointments WHERE status = 'pending'
);
```

### Step 3: Test API Directly
Test the pending appointments API directly:
```bash
curl -H "Authorization: Bearer [admin_token]" \
  http://localhost:3000/api/admin/pending-appointments
```

### Step 4: Check Survey Submission
Verify that patients are actually submitting surveys:
```sql
SELECT COUNT(*) as survey_count FROM dental_surveys;
SELECT COUNT(*) as pending_appointments FROM appointments WHERE status = 'pending';
```

## Expected Behavior

When survey data is available, the pending appointment details should show:
1. **Question 1**: Tooth Conditions (with selected conditions)
2. **Question 2**: Tartar Level
3. **Question 3**: Tooth Sensitivity (Yes/No)
4. **Question 4**: Tooth Pain (Yes/No)
5. **Question 5**: Gum Problems (Yes/No)
6. **Question 6**: Missing Teeth (with conditions)
7. **Question 7**: Previous Dental Work (Yes/No)
8. **Question 8**: Last Dental Visit

When no survey data is available, it should show:
- "No survey data available for this patient."

## Next Steps

1. ✅ Check the console logs for survey data debug information
2. ✅ Verify if patients have actually completed surveys
3. ✅ Test the API endpoint directly
4. ✅ Check database for survey data existence
5. ✅ **FIXED**: Added format conversion to handle old survey data format

## Solution Implemented ✅

The issue has been resolved by adding a format conversion method `_convertOldSurveyFormat()` that:

1. **Detects old format**: Checks if survey data contains `question1`, `question2`, etc.
2. **Converts to new format**: Maps old question format to new field names
3. **Displays correctly**: Uses converted data to show all 8 questions in the admin dashboard

The pending appointment details should now properly display the patient self-assessment survey data for all appointments that have survey data in the database. 