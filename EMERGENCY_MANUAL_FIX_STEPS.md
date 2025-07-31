# 🚨 Emergency Database Manual Fix - IMMEDIATE ACTION REQUIRED

## 🔴 Current Problem
The admin emergencies tab is showing **500 errors** because the `emergency_records` table is missing 8 critical columns.

## ✅ Solution: Manual Database Update

### Step 1: Access Railway Database
1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click on your dental app project
3. Click on your **PostgreSQL** database
4. Click **"Query"** tab

### Step 2: Run These SQL Commands (Copy & Paste)

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

### Step 3: Verify the Fix
Run this query to check if all columns exist:

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

You should see these columns:
- `id`
- `patient_id`
- `emergency_date`
- `emergency_type`
- `description`
- `severity`
- `resolved`
- `created_at`
- `status` ✅ (new)
- `priority` ✅ (new)
- `handled_by` ✅ (new)
- `resolution` ✅ (new)
- `follow_up_required` ✅ (new)
- `resolved_at` ✅ (new)
- `emergency_contact` ✅ (new)
- `notes` ✅ (new)

### Step 4: Test the Fix
After running the SQL commands:

1. **Restart your Flutter app**
2. **Login as admin**
3. **Go to Emergencies tab**
4. **Verify it loads without 500 errors**

## 🎯 Expected Results
- ✅ Admin emergencies tab loads without errors
- ✅ Emergency records display correctly
- ✅ Remove button works
- ✅ Status updates work
- ✅ All emergency features functional

## 🔧 Alternative: Use the Script
If you prefer using a script:

1. Get your Railway PostgreSQL connection string from Railway dashboard
2. Set it as environment variable:
   ```bash
   set DATABASE_URL=postgresql://username:password@host:port/database
   ```
3. Run: `node fix_emergency_database_direct.js`

## 📞 If You Need Help
1. Check Railway logs for any SQL errors
2. Verify all SQL commands executed successfully
3. Make sure you're connected to the correct database
4. Test with a fresh emergency record creation

## ⚠️ Important Notes
- This fix only affects the database schema
- No data will be lost
- The backend code already has the COALESCE fix
- This is a one-time fix - no need to repeat 