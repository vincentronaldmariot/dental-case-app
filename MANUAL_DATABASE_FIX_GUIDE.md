# Manual Database Fix Guide

## Problem
The admin dashboard is failing to load all features with 500 errors because the Railway backend is not connecting to the database properly.

## Root Cause
The `DATABASE_URL` and `DATABASE_PUBLIC_URL` environment variables in Railway are not properly formatted.

## Solution

### Step 1: Go to Railway Dashboard
1. Open your browser and go to [Railway Dashboard](https://railway.app/dashboard)
2. Navigate to your "AFP dental app" project
3. Click on the "Postgres" service

### Step 2: Update Environment Variables
1. Click on the "Variables" tab
2. Find the following variables and update them:

#### Update DATABASE_URL
- **Current value**: `PGPASSWORD="glfJbkmkHHAAlKQqFzNtkMQjXOPjJthr" psql -h ballast.proxy.rlwy.net -U postgres -p 27199 -d railway`
- **New value**: `postgresql://postgres:glfJbkmkHHAAlKQqFzNtkMQjXOPjJthr@ballast.proxy.rlwy.net:27199/railway`

#### Update DATABASE_PUBLIC_URL
- **Current value**: `postgresql://` (incomplete)
- **New value**: `postgresql://postgres:glfJbkmkHHAAlKQqFzNtkMQjXOPjJthr@ballast.proxy.rlwy.net:27199/railway`

### Step 3: Save Changes
1. Click "Save" to update the variables
2. Railway will automatically redeploy your application

### Step 4: Wait for Deployment
1. Go to the "Deployments" tab
2. Wait for the deployment to complete (should take 1-2 minutes)
3. Look for a green checkmark indicating successful deployment

### Step 5: Test the Fix
1. Go back to your Flutter app
2. Try logging into the admin dashboard
3. All features should now load properly:
   - Dashboard stats
   - Approved appointments
   - Pending appointments
   - Emergency records
   - Patient list

## Verification
After the fix, you should see:
- ✅ Dashboard loads with statistics
- ✅ Approved appointments list loads
- ✅ Pending appointments list loads
- ✅ Emergency records list loads
- ✅ Patient history loads
- ✅ No more 500 errors

## Connection Details (for reference)
- **Host**: ballast.proxy.rlwy.net
- **Port**: 27199
- **Database**: railway
- **Username**: postgres
- **Password**: glfJbkmkHHAAlKQqFzNtkMQjXOPjJthr

## If Issues Persist
If you still see 500 errors after the fix:
1. Check the Railway logs in the "Logs" tab
2. Ensure the deployment completed successfully
3. Try accessing the admin dashboard again after a few minutes 