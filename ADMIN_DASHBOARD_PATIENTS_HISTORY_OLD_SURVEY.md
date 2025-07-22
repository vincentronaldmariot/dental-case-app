# Admin Dashboard Patients History - Old Self-Assessment Survey

## Overview
Updated the admin dashboard patients history section to use the old self-assessment survey format (questions 1-8) instead of generic questions.

## Changes Made

### 1. Updated Question Labels ✅
**File**: `lib/admin_dashboard_screen.dart`
**Method**: `_buildSurveyDataSection()`

**Before**:
```dart
const Map<String, String> questionLabels = {
  'question1': 'Do you experience tooth pain or sensitivity?',
  'question2': 'Do you have bleeding gums when brushing?',
  'question3': 'Do you have bad breath or taste issues?',
  'question4': 'Do you have loose or shifting teeth?',
  'question5': 'Do you have difficulty chewing or biting?',
  'question6': 'Do you have jaw pain or clicking sounds?',
  'question7': 'Do you have dry mouth or excessive thirst?',
  'question8': 'Do you have any visible cavities or dark spots?',
};
```

**After**:
```dart
const Map<String, String> questionLabels = {
  'question1': '1. Do you have any of the ones shown in the pictures?',
  'question2': '2. Do you have tartar/calculus deposits or rough feeling teeth like in the images?',
  'question3': '3. Do your teeth feel sensitive to hot, cold, or sweet foods?',
  'question4': '4. Do you experience tooth pain?',
  'question5': '5. Do you have damaged or broken fillings like those shown in the pictures?',
  'question6': '6. Do you need to get dentures (false teeth)?',
  'question7': '7. Do you have missing or extracted teeth?',
  'question8': '8. When was your last dental visit at a Dental Treatment Facility?',
};
```

### 2. Simplified Survey Data Fetching ✅
**File**: `lib/admin_dashboard_screen.dart`
**Method**: `_fetchPatientSurveyData()`

**Changes**:
- Removed unnecessary mapping from new survey format to old format
- Focused on using the old survey format directly (`question1`, `question2`, etc.)
- Added debug logging when no old survey format is found
- Simplified the data processing logic

**Before**:
```dart
// Complex mapping from new format to old format
if (surveyData.containsKey('pain_level')) {
  formattedData['question1'] = _formatPainLevel(surveyData['pain_level']);
}
// ... more mappings
```

**After**:
```dart
// Use the old self-assessment survey format directly
if (surveyData.containsKey('question1') || surveyData.containsKey('question_1')) {
  for (int i = 1; i <= 8; i++) {
    final key = 'question$i';
    final altKey = 'question_$i';
    if (surveyData.containsKey(key)) {
      formattedData[key] = surveyData[key];
    } else if (surveyData.containsKey(altKey)) {
      formattedData[key] = surveyData[altKey];
    }
  }
} else {
  print('No old survey format found for patient $patientId');
}
```

## Backend API ✅
**File**: `backend/routes/admin.js`
**Endpoint**: `GET /api/admin/patients/:id/survey`

The backend API is already correctly configured to:
- Fetch survey data from the `dental_surveys` table
- Return the data in its original format (old survey format)
- Handle JSON parsing if needed
- Return proper error responses

## Expected Behavior ✅

When viewing a patient's history in the admin dashboard:

1. **Survey Section Title**: "Self Assessment Survey (1-8)"
2. **Question Display**: All 8 questions from the old self-assessment survey
3. **Answer Format**: Shows the actual patient responses
4. **Visual Indicators**: 
   - Question numbers in blue circles
   - Color-coded answers (red for Yes, green for No, orange for Sometimes)
   - Icons indicating response type (warning for Yes, check for No, etc.)

## Questions Displayed ✅

1. **Question 1**: "Do you have any of the ones shown in the pictures?"
2. **Question 2**: "Do you have tartar/calculus deposits or rough feeling teeth like in the images?"
3. **Question 3**: "Do your teeth feel sensitive to hot, cold, or sweet foods?"
4. **Question 4**: "Do you experience tooth pain?"
5. **Question 5**: "Do you have damaged or broken fillings like those shown in the pictures?"
6. **Question 6**: "Do you need to get dentures (false teeth)?"
7. **Question 7**: "Do you have missing or extracted teeth?"
8. **Question 8**: "When was your last dental visit at a Dental Treatment Facility?"

## Data Flow ✅

1. **Patient History Button**: Click "History" button on patient card
2. **API Call**: `_fetchPatientSurveyData()` calls `/api/admin/patients/:id/survey`
3. **Backend**: Returns survey data in old format (`question1`, `question2`, etc.)
4. **Frontend**: Displays questions 1-8 with correct labels and patient responses
5. **UI**: Shows formatted survey data with visual indicators and proper styling

## Compatibility ✅

- **Backward Compatible**: Works with existing survey data in the database
- **Format Agnostic**: Handles both `question1` and `question_1` formats
- **Error Handling**: Gracefully handles missing survey data
- **Debug Logging**: Provides console output for troubleshooting

The admin dashboard patients history now correctly displays the old self-assessment survey data with the proper 8 questions and maintains consistency with the rest of the application. 