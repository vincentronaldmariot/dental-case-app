# 🔧 Connecting to Railway Database with DBeaver

## 📋 Prerequisites
1. Download DBeaver Community Edition: https://dbeaver.io/download/
2. Install DBeaver
3. Get your Railway database connection details

## 🚀 Step-by-Step Connection Guide

### Step 1: Get Railway Connection Details
1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click your dental app project
3. Click your **PostgreSQL** database
4. Click **"Connect"** tab
5. Copy these details:
   - **Host**: `containers-us-west-XX.railway.app`
   - **Port**: `5432`
   - **Database**: `railway`
   - **Username**: `postgres`
   - **Password**: (copy from Railway)

### Step 2: Connect with DBeaver
1. **Open DBeaver**
2. **Click "New Database Connection"** (plug icon)
3. **Select "PostgreSQL"** → Click "Next"
4. **Fill in connection details**:
   - **Server Host**: Your Railway host
   - **Port**: `5432`
   - **Database**: `railway`
   - **Username**: `postgres`
   - **Password**: Your Railway password
5. **Click "Test Connection"**
6. **Click "Finish"**

### Step 3: Run the Emergency Fix SQL
1. **Right-click your database** → "SQL Editor" → "New SQL Script"
2. **Copy and paste this SQL**:

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

3. **Click "Execute SQL Script"** (play button)
4. **Verify the results**

### Step 4: Verify the Fix
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

## 🎯 Expected Results
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

## ✅ After the Fix
1. **Restart your Flutter app**
2. **Login as admin**
3. **Go to Emergencies tab**
4. **Verify it loads without 500 errors**

## 🔧 Troubleshooting
- **Connection timeout**: Increase connection timeout in DBeaver settings
- **SSL error**: Make sure SSL is enabled in connection settings
- **Authentication failed**: Double-check username/password from Railway 