# 📍 WHERE TO FIND THE QUERY IN RAILWAY

## Step-by-Step Guide with Screenshots

### Step 1: Open Railway Dashboard
1. Go to: https://railway.app
2. Sign in to your account

### Step 2: Find Your Project
1. Look for the project named: **`afp-dental-app-production`**
2. Click on it to open the project dashboard

### Step 3: Find the Database Service
In your project dashboard, you'll see **TWO services**:
- **Node.js service** (your backend code) - DON'T click this
- **PostgreSQL service** (your database) - **CLICK THIS ONE**

The PostgreSQL service usually has:
- A database icon (🗄️)
- Name like "PostgreSQL" or "Database"
- Status showing "Running"

### Step 4: Access the Query Editor
1. Click on the **PostgreSQL service**
2. In the service page, look for tabs or sections
3. Find and click **"Connect"** or **"Query"** or **"SQL Editor"**
4. This will open the database query interface

### Step 5: Run the SQL Command
1. You'll see a text area where you can type SQL
2. Copy and paste this command:

```sql
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
```

3. Click **"Run"**, **"Execute"**, or **"Submit"** button

## 🎯 What You Should See

### Before Running:
- Empty query editor
- "Run" button available

### After Running:
- Success message like "Query executed successfully"
- Or "INSERT 0 1" (meaning 1 row inserted)

## 🔍 Alternative Locations

If you don't see "Connect" or "Query", look for:
- **"SQL Editor"**
- **"Database"** tab
- **"Query"** tab
- **"Console"** or **"Terminal"**

## ❓ Still Can't Find It?

If you can't find the query section:
1. Make sure you clicked on the **PostgreSQL service** (not Node.js)
2. Look for any database-related tabs or buttons
3. The interface might be slightly different depending on your Railway plan

## 🚀 After Running the Query

Once you successfully run the SQL command:
1. Go back to your Flutter app
2. Try submitting the survey again
3. It should work without the 404 error! 