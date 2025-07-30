# Admin Emergencies Tab Fix Guide

## 🔴 Problem
The admin emergencies tab is showing a 500 error: "Failed to retrieve emergency records. Please try again."

## 🔍 Root Cause
The `emergency_records` table is missing 8 critical columns that the admin emergency query expects:
- `status`
- `priority` 
- `handled_by`
- `resolution`
- `follow_up_required`
- `resolved_at`
- `emergency_contact`
- `notes`

## ✅ Solution Applied

### 1. Backend Code Fix
I've updated the admin emergency queries in `backend/routes/admin.js` to use `COALESCE` for missing columns:

```sql
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
```

### 2. Manual Database Update Required

You need to manually add the missing columns to your Railway PostgreSQL database:

#### Step 1: Connect to Railway Database
1. Go to your Railway project dashboard
2. Click on your PostgreSQL database
3. Open the "Query" tab or use pgAdmin

#### Step 2: Run These SQL Commands

```sql
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
```

#### Step 3: Verify the Schema
Run this query to verify all columns exist:

```sql
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'emergency_records' 
ORDER BY ordinal_position;
```

### 3. Deploy Backend Changes
After updating the database, deploy the backend changes to Railway:

```bash
git add .
git commit -m "Fix admin emergencies tab - add COALESCE for missing columns"
git push origin main
```

## 🧪 Testing

After completing the above steps, test the admin emergencies tab:

1. **Login as admin** in the Flutter app
2. **Navigate to the Emergencies tab**
3. **Verify it loads without errors**
4. **Test emergency record creation and status updates**

## 📋 Expected Results

After the fix:
- ✅ Admin emergencies tab loads without 500 errors
- ✅ Emergency records display correctly
- ✅ Emergency status updates work
- ✅ Emergency record creation works
- ✅ All emergency management features functional

## 🔧 Alternative Quick Fix

If you can't immediately update the database, the backend code changes will provide a temporary workaround using default values, but you should still add the missing columns for full functionality.

## 📞 Support

If you encounter any issues:
1. Check Railway logs for database errors
2. Verify all SQL commands executed successfully
3. Ensure the backend code changes are deployed
4. Test with a fresh emergency record creation 