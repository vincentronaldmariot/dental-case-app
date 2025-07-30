# Pending Appointments Fix Guide

## Current Issue
The pending appointments are not showing in the admin appointment tab because the Railway deployment has routing issues. The server is running (health endpoint works) but API routes are returning 404 errors.

## Root Cause
The Railway deployment is not properly serving the API routes, likely due to:
1. Old cached deployment
2. Missing environment variables
3. Incorrect routing configuration

## Solution Steps

### Step 1: Force Railway Restart
1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Select your "AFP dental app" project
3. Click on the "AFP dental app" service
4. Go to the "Settings" tab
5. Click the "Restart" button
6. Wait 2-3 minutes for the restart to complete

### Step 2: Check Environment Variables
1. In the same service, go to the "Variables" tab
2. Ensure these variables are set:
   ```
   DATABASE_URL=your_postgresql_connection_string
   JWT_SECRET=your_jwt_secret
   NODE_ENV=production
   PORT=3000
   ```
3. Add a new variable to force restart:
   ```
   FORCE_RESTART=true
   ```
4. Save the variables

### Step 3: Verify the Fix
After the restart, test the endpoints:

```bash
# Test health endpoint
curl https://afp-dental-app-production.up.railway.app/health

# Test admin login
curl -X POST https://afp-dental-app-production.up.railway.app/api/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@dental.com","password":"admin123"}'

# Test pending appointments (with token from login)
curl https://afp-dental-app-production.up.railway.app/api/admin/appointments/pending \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Step 4: Test in Flutter App
1. Open your Flutter app
2. Login as admin
3. Go to the admin dashboard
4. Check the "Appointments" tab
5. Pending appointments should now be visible

## Alternative: Local Testing
If Railway continues to have issues, you can test locally:

1. Start your local backend:
   ```bash
   cd backend
   npm start
   ```

2. Update `lib/config/app_config.dart`:
   ```dart
   static const bool isOnlineMode = false; // Set to false for local testing
   ```

3. Test the app locally to verify pending appointments work

## Expected Results
After the Railway restart:
- ✅ Health endpoint: `https://afp-dental-app-production.up.railway.app/health` returns 200
- ✅ API routes: `/api/auth`, `/api/admin` return proper responses
- ✅ Pending appointments endpoint: `/api/admin/appointments/pending` returns appointment data
- ✅ Flutter admin dashboard shows pending appointments in the appointments tab

## Debugging Commands
If issues persist, run these test scripts:

```bash
# Test Railway status
node test_railway_status.js

# Test pending appointments specifically
node test_pending_appointments_debug.js

# Test all admin endpoints
node final_admin_fix_test.js
```

## Common Issues and Solutions

### Issue: 404 errors on all API routes
**Solution:** Force Railway restart (Step 1)

### Issue: Authentication errors
**Solution:** Check JWT_SECRET environment variable

### Issue: Database connection errors
**Solution:** Check DATABASE_URL environment variable

### Issue: Pending appointments still not showing
**Solution:** 
1. Check if there are actually pending appointments in the database
2. Verify the appointment status is 'pending'
3. Check if the admin token is valid

## Database Check
To verify pending appointments exist:

```sql
-- Check all appointments
SELECT id, patient_id, service, appointment_date, status 
FROM appointments 
ORDER BY created_at DESC;

-- Check pending appointments specifically
SELECT id, patient_id, service, appointment_date, status 
FROM appointments 
WHERE status = 'pending'
ORDER BY created_at DESC;
```

## Contact Support
If the issue persists after following these steps:
1. Check Railway logs for deployment errors
2. Verify all environment variables are correct
3. Consider redeploying the entire project 